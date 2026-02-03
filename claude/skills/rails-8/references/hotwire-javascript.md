# Hotwire and JavaScript Reference

Rails 8 uses Hotwire as the default frontend framework, providing modern interactivity without heavy JavaScript.

## Hotwire Stack Overview

| Component | Purpose |
|-----------|---------|
| **Turbo Drive** | Accelerates page navigation |
| **Turbo Frames** | Partial page updates |
| **Turbo Streams** | Real-time DOM updates |
| **Stimulus** | Lightweight JavaScript controllers |

## Import Maps

Rails 8 uses import maps for JavaScript package management without bundlers.

### Configuration

```ruby
# config/importmap.rb
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Add external packages
pin "lodash", to: "https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js"
```

### Adding Packages

```bash
bin/importmap pin react
bin/importmap pin lodash --download  # Downloads to vendor/javascript
bin/importmap unpin lodash
```

### Application Entry Point

```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "controllers"
```

---

## Turbo Drive

Intercepts link clicks and form submissions, replacing full page loads with fetch requests.

### Enabled by Default

All navigation is accelerated automatically. Disable for specific elements:

```erb
<%# Disable on single link %>
<%= link_to "External", "https://example.com", data: { turbo: false } %>

<%# Disable for entire section %>
<div data-turbo="false">
  <%= link_to "Normal Link", some_path %>
</div>
```

### Progress Bar

```css
/* Customize the progress bar */
.turbo-progress-bar {
  height: 3px;
  background-color: #0066cc;
}
```

### Caching

```erb
<%# Preview cached version while fetching %>
<meta name="turbo-cache-control" content="no-preview">

<%# Disable caching for page %>
<meta name="turbo-cache-control" content="no-cache">
```

---

## Turbo Frames

Update specific page regions without full reloads.

### Basic Frame

```erb
<%# app/views/messages/index.html.erb %>
<%= turbo_frame_tag "messages" do %>
  <% @messages.each do |message| %>
    <%= render message %>
  <% end %>
<% end %>

<%# Links within frame stay in frame %>
<%= link_to "More", messages_path(page: 2) %>
```

### Loading Content from Another Page

```erb
<%# Loads content from /messages into frame %>
<%= turbo_frame_tag "messages", src: messages_path %>

<%# With loading placeholder %>
<%= turbo_frame_tag "messages", src: messages_path do %>
  <p>Loading messages...</p>
<% end %>
```

### Breaking Out of Frames

```erb
<%# Target parent frame %>
<%= link_to "View All", messages_path, data: { turbo_frame: "_top" } %>

<%# Target specific frame %>
<%= link_to "Edit", edit_message_path(message), data: { turbo_frame: "modal" } %>
```

### Lazy Loading

```erb
<%# Load when visible %>
<%= turbo_frame_tag "comments", src: comments_path, loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

### Frame with Form

```erb
<%= turbo_frame_tag dom_id(@message) do %>
  <%= render @message %>

  <%= link_to "Edit", edit_message_path(@message) %>
<% end %>

<%# edit.html.erb %>
<%= turbo_frame_tag dom_id(@message) do %>
  <%= form_with model: @message do |f| %>
    <%= f.text_field :content %>
    <%= f.submit %>
  <% end %>
<% end %>
```

---

## Turbo Streams

Real-time DOM manipulation via WebSocket or HTTP responses.

### Stream Actions

| Action | Description |
|--------|-------------|
| `append` | Add to end of target |
| `prepend` | Add to beginning of target |
| `replace` | Replace entire target |
| `update` | Update target's innerHTML |
| `remove` | Remove target element |
| `before` | Insert before target |
| `after` | Insert after target |
| `morph` | Morph target content |
| `refresh` | Trigger page refresh |

### HTTP Response Streams

```ruby
class MessagesController < ApplicationController
  def create
    @message = Message.create!(message_params)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to messages_path }
    end
  end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to messages_path }
    end
  end
end
```

```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.prepend "messages", @message %>
<%= turbo_stream.update "message_count", Message.count %>
<%= turbo_stream.update "flash", partial: "shared/flash" %>
```

### Model Broadcasts (Real-time)

```ruby
class Message < ApplicationRecord
  broadcasts_to :room
  # Automatically broadcasts create/update/destroy to room's stream
end

class Comment < ApplicationRecord
  broadcasts
  # Broadcasts to "comments" stream
end

class Post < ApplicationRecord
  after_create_commit -> { broadcast_prepend_to "posts" }
  after_update_commit -> { broadcast_replace_to "posts" }
  after_destroy_commit -> { broadcast_remove_to "posts" }
end
```

```erb
<%# Subscribe to streams in view %>
<%= turbo_stream_from @room %>
<%= turbo_stream_from "posts" %>

<div id="messages">
  <%= render @room.messages %>
</div>
```

### Custom Broadcasts

```ruby
class Message < ApplicationRecord
  after_create_commit :broadcast_message

  private

  def broadcast_message
    broadcast_prepend_to(
      room,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end
end
```

---

## Stimulus

Modest JavaScript framework for enhancing HTML.

### Controller Structure

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = { name: String }
  static classes = ["active"]

  connect() {
    console.log("Hello controller connected")
  }

  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameValue}!`
    this.element.classList.add(this.activeClass)
  }
}
```

### HTML Integration

```erb
<div data-controller="hello" data-hello-name-value="World" data-hello-active-class="highlighted">
  <input data-hello-target="output">
  <button data-action="click->hello#greet">Greet</button>
</div>
```

### Generating Controllers

```bash
bin/rails generate stimulus search
```

### Targets

```javascript
export default class extends Controller {
  static targets = ["input", "results", "count"]

  search() {
    const query = this.inputTarget.value
    // this.resultsTarget, this.countTarget
    // this.hasResultsTarget (boolean)
    // this.resultsTargets (array of all matching)
  }
}
```

### Values

```javascript
export default class extends Controller {
  static values = {
    url: String,
    count: { type: Number, default: 0 },
    active: Boolean,
    items: Array,
    config: Object
  }

  connect() {
    console.log(this.urlValue)
    console.log(this.countValue)
  }

  // Called when value changes
  countValueChanged(value, previousValue) {
    console.log(`Count changed from ${previousValue} to ${value}`)
  }
}
```

```erb
<div data-controller="example"
     data-example-url-value="<%= api_url %>"
     data-example-count-value="5"
     data-example-active-value="true"
     data-example-items-value="<%= [1,2,3].to_json %>"
     data-example-config-value="<%= {key: 'value'}.to_json %>">
</div>
```

### Actions

```erb
<%# Click action %>
<button data-action="click->controller#method">Click</button>

<%# Multiple actions %>
<input data-action="input->search#query keydown.enter->search#submit">

<%# Form submission %>
<form data-action="submit->form#validate">

<%# Custom events %>
<div data-action="custom:event->controller#handle">

<%# Action options %>
<button data-action="click->controller#method:prevent">No Default</button>
<button data-action="click->controller#method:stop">Stop Propagation</button>
```

### Lifecycle Callbacks

```javascript
export default class extends Controller {
  initialize() {
    // Once per controller class
  }

  connect() {
    // Element inserted into DOM
  }

  disconnect() {
    // Element removed from DOM
  }
}
```

### Multiple Controllers

```erb
<div data-controller="clipboard tooltip"
     data-clipboard-content-value="Copy this"
     data-tooltip-text-value="Click to copy">
  <button data-action="click->clipboard#copy mouseenter->tooltip#show">
    Copy
  </button>
</div>
```

### Controller Communication

```javascript
// Dispatch custom event
export default class extends Controller {
  select() {
    this.dispatch("selected", { detail: { id: this.idValue } })
  }
}

// Listen in another controller
export default class extends Controller {
  handleSelection({ detail: { id } }) {
    console.log(`Selected: ${id}`)
  }
}
```

```erb
<div data-controller="parent" data-action="child:selected->parent#handleSelection">
  <div data-controller="child" data-child-id-value="123">
    <button data-action="click->child#select">Select</button>
  </div>
</div>
```

---

## Common Patterns

### Modal

```javascript
// app/javascript/controllers/modal_controller.js
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }
}
```

```erb
<div data-controller="modal">
  <button data-action="click->modal#open">Open Modal</button>

  <dialog data-modal-target="dialog" data-action="click->modal#clickOutside">
    <div class="modal-content">
      <h2>Modal Title</h2>
      <button data-action="click->modal#close">Close</button>
    </div>
  </dialog>
</div>
```

### Debounced Search

```javascript
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fetchResults()
    }, 300)
  }

  async fetchResults() {
    const response = await fetch(`${this.urlValue}?q=${this.inputTarget.value}`)
    this.resultsTarget.innerHTML = await response.text()
  }
}
```

### Form Validation

```javascript
export default class extends Controller {
  static targets = ["submit"]

  validate() {
    const form = this.element
    this.submitTarget.disabled = !form.checkValidity()
  }
}
```

## Best Practices

1. **Prefer Turbo over custom JS** - Most interactions don't need JavaScript
2. **Use Turbo Frames for partial updates** - Simpler than Turbo Streams
3. **Keep Stimulus controllers small** - Single responsibility
4. **Use data attributes** - Avoid inline event handlers
5. **Leverage morphing** - For smooth updates without layout shift
6. **Test with system tests** - Capybara handles Turbo automatically
