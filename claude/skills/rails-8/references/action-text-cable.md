# Action Text and Action Cable Reference

## Action Text

Action Text provides rich text content and editing using the Trix editor.

### Setup

```bash
bin/rails action_text:install
bin/rails db:migrate
```

Installs:

- Trix editor JavaScript
- `@rails/actiontext` package
- Database migration for `action_text_rich_texts`
- Default styling in `app/assets/stylesheets/actiontext.css`

### Adding Rich Text to Models

```ruby
class Article < ApplicationRecord
  has_rich_text :content
  has_rich_text :summary  # Multiple rich text fields
end
```

### Forms

```erb
<%= form_with model: @article do |form| %>
  <%= form.label :title %>
  <%= form.text_field :title %>

  <%= form.label :content %>
  <%= form.rich_textarea :content %>

  <%= form.submit %>
<% end %>
```

### Controller

```ruby
class ArticlesController < ApplicationController
  def create
    @article = Article.new(article_params)
    @article.save
  end

  private

  def article_params
    params.expect(article: [:title, :content])
  end
end
```

### Rendering Content

```erb
<%# Renders sanitized HTML %>
<%= @article.content %>

<%# Plain text version %>
<%= @article.content.to_plain_text %>

<%# Check for content %>
<% if @article.content.present? %>
  <%= @article.content %>
<% end %>
```

### Eager Loading

Prevent N+1 queries:

```ruby
# Load rich text content
Article.with_rich_text_content

# Load with embedded attachments
Article.with_rich_text_content_and_embeds
```

### Customizing Attachments

Create custom rendering for embedded content:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include ActionText::Attachable

  def to_trix_content_attachment_partial_path
    "users/trix_attachment"
  end
end
```

```erb
<%# app/views/users/_trix_attachment.html.erb %>
<span class="user-mention">@<%= user.name %></span>
```

### Styling

```css
/* app/assets/stylesheets/actiontext.css */
.trix-content {
  max-width: 65ch;
}

.trix-content h1 {
  font-size: 1.5rem;
  margin-bottom: 1rem;
}

.trix-content blockquote {
  border-left: 3px solid #ccc;
  padding-left: 1rem;
  color: #666;
}

/* Attachment styling */
.trix-content .attachment {
  display: inline-block;
  max-width: 100%;
}
```

---

## Action Cable

Action Cable integrates WebSockets for real-time features.

### Server-Side Setup

#### Connection (app/channels/application_cable/connection.rb)

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if verified_user = User.find_by(id: cookies.encrypted[:user_id])
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

#### Channel Base (app/channels/application_cable/channel.rb)

```ruby
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

### Creating Channels

```bash
bin/rails generate channel Chat speak
```

```ruby
# app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_#{params[:room]}"
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
  end

  def speak(data)
    Message.create!(
      content: data["message"],
      user: current_user,
      room: params[:room]
    )
  end
end
```

### Model Broadcasting

```ruby
class Message < ApplicationRecord
  belongs_to :user
  belongs_to :room

  after_create_commit :broadcast_message

  private

  def broadcast_message
    ActionCable.server.broadcast(
      "chat_#{room_id}",
      {
        message: render_message,
        user: user.name,
        created_at: created_at.strftime("%H:%M")
      }
    )
  end

  def render_message
    ApplicationController.renderer.render(
      partial: "messages/message",
      locals: { message: self }
    )
  end
end
```

### Turbo Streams Integration

Rails 8 integrates Action Cable with Turbo Streams:

```ruby
class Message < ApplicationRecord
  broadcasts_to :room
end
```

```erb
<%# app/views/rooms/show.html.erb %>
<%= turbo_stream_from @room %>

<div id="messages">
  <%= render @room.messages %>
</div>
```

### Client-Side (JavaScript)

```javascript
// app/javascript/channels/chat_channel.js
import consumer from "channels/consumer"

consumer.subscriptions.create(
  { channel: "ChatChannel", room: "general" },
  {
    connected() {
      console.log("Connected to chat")
    },

    disconnected() {
      console.log("Disconnected from chat")
    },

    received(data) {
      const messages = document.getElementById("messages")
      messages.insertAdjacentHTML("beforeend", data.message)
    },

    speak(message) {
      this.perform("speak", { message: message })
    }
  }
)
```

### Consumer Setup

```javascript
// app/javascript/channels/consumer.js
import { createConsumer } from "@rails/actioncable"

export default createConsumer()
```

### Stream Methods

```ruby
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Stream from named channel
    stream_from "notifications_#{current_user.id}"
  end
end

class CommentsChannel < ApplicationCable::Channel
  def subscribed
    @post = Post.find(params[:post_id])
    # Stream for model (auto-generates channel name)
    stream_for @post
  end
end
```

### Broadcasting

```ruby
# From anywhere in your application
ActionCable.server.broadcast("chat_general", { message: "Hello!" })

# For model-based streams
CommentsChannel.broadcast_to(post, { comment: "New comment" })

# From controller
class MessagesController < ApplicationController
  def create
    @message = Message.create!(message_params)
    ActionCable.server.broadcast(
      "chat_#{@message.room_id}",
      render_to_string(partial: "messages/message", locals: { message: @message })
    )
    head :ok
  end
end
```

### Configuration

```ruby
# config/cable.yml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: solid_cable  # Rails 8 default, database-backed
  # or
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: myapp_production
```

### Solid Cable (Rails 8)

Database-backed adapter without Redis:

```bash
bin/rails solid_cable:install
```

```yaml
# config/cable.yml
production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
```

### Testing

```ruby
class ChatChannelTest < ActionCable::Channel::TestCase
  test "subscribes to room" do
    subscribe room: "general"

    assert subscription.confirmed?
    assert_has_stream "chat_general"
  end

  test "speaks message" do
    subscribe room: "general"

    assert_difference "Message.count" do
      perform :speak, message: "Hello!"
    end
  end
end
```

```ruby
class MessagesTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  test "broadcasts message" do
    assert_broadcast_on("chat_general", message: "Hello!") do
      post messages_url, params: { message: { content: "Hello!", room: "general" } }
    end
  end
end
```

### Connection Testing

```ruby
class ConnectionTest < ActionCable::Connection::TestCase
  test "connects with valid user" do
    user = users(:john)
    cookies.encrypted[:user_id] = user.id

    connect

    assert_equal user, connection.current_user
  end

  test "rejects without user" do
    assert_reject_connection { connect }
  end
end
```

## Best Practices

### Rich Text Best Practices

1. **Sanitize on output** - Action Text sanitizes by default, don't use `raw`
2. **Eager load** - Use `with_rich_text_*` scopes to prevent N+1
3. **Limit uploads** - Configure Active Storage limits for embedded files

### WebSocket Best Practices

1. **Authenticate connections** - Always verify users in the connection class
2. **Use Turbo Streams** - Simplifies broadcasting with less JavaScript
3. **Handle disconnections** - Clean up resources in `unsubscribed`
4. **Namespace channels** - Include user/room IDs in stream names
5. **Rate limit** - Prevent abuse of real-time channels
6. **Use Solid Cable in production** - Simpler than Redis for most apps
