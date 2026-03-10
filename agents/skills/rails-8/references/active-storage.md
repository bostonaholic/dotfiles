# Active Storage Reference

Active Storage handles file uploads to cloud storage services (S3, GCS, Azure) or local disk.

## Setup

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

Creates three tables:

- `active_storage_blobs` - File metadata
- `active_storage_attachments` - Polymorphic join table
- `active_storage_variant_records` - Variant tracking

## Configuration

### Storage Services (config/storage.yml)

```yaml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

amazon:
  service: S3
  access_key_id: <%= ENV["AWS_ACCESS_KEY_ID"] %>
  secret_access_key: <%= ENV["AWS_SECRET_ACCESS_KEY"] %>
  region: us-east-1
  bucket: my-app-production

google:
  service: GCS
  project: my-project
  credentials: <%= Rails.root.join("config/gcs.json") %>
  bucket: my-app-production

azure:
  service: AzureStorage
  storage_account_name: my-account
  storage_access_key: <%= ENV["AZURE_STORAGE_KEY"] %>
  container: my-container

mirror:
  service: Mirror
  primary: amazon
  mirrors:
    - google
```

### Environment Configuration

```ruby
# config/environments/development.rb
config.active_storage.service = :local

# config/environments/production.rb
config.active_storage.service = :amazon
```

## Attaching Files

### Single Attachment (has_one_attached)

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
end
```

```ruby
# Attach from form upload
user.avatar.attach(params[:avatar])

# Attach from file
user.avatar.attach(
  io: File.open("/path/to/file.jpg"),
  filename: "avatar.jpg",
  content_type: "image/jpeg"
)

# Attach from URL
user.avatar.attach(
  io: URI.open("https://example.com/image.jpg"),
  filename: "avatar.jpg"
)

# Check attachment
user.avatar.attached?  # => true

# Access URL
url_for(user.avatar)
rails_blob_path(user.avatar, disposition: "attachment")

# Remove attachment
user.avatar.purge        # Synchronous
user.avatar.purge_later  # Background job
```

### Multiple Attachments (has_many_attached)

```ruby
class Message < ApplicationRecord
  has_many_attached :images
end
```

```ruby
# Attach multiple files
message.images.attach(params[:images])

# Append to existing
message.images.attach(new_image)

# Access all
message.images.each do |image|
  url_for(image)
end

# Count
message.images.count
message.images.any?

# Purge specific
message.images.find(id).purge_later

# Purge all
message.images.purge_later
```

## Forms

### Single File Upload

```erb
<%= form_with model: @user do |form| %>
  <%= form.file_field :avatar %>
  <%= form.submit %>
<% end %>
```

### Multiple Files

```erb
<%= form_with model: @message do |form| %>
  <%= form.file_field :images, multiple: true %>
  <%= form.submit %>
<% end %>
```

### Direct Uploads

Enable uploads directly to cloud storage:

```erb
<%= form_with model: @user do |form| %>
  <%= form.file_field :avatar, direct_upload: true %>
  <%= form.submit %>
<% end %>
```

Requires JavaScript:

```javascript
// app/javascript/application.js
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
```

### Controller Params

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    @user.save
  end

  private

  def user_params
    params.expect(user: [:name, :avatar])
  end
end

class MessagesController < ApplicationController
  private

  def message_params
    params.expect(message: [:body, images: []])
  end
end
```

## Image Variants

Requires `image_processing` gem and libvips or ImageMagick.

```ruby
# Gemfile
gem "image_processing", "~> 1.2"
```

### Creating Variants

```erb
<%# Resize to fit within dimensions %>
<%= image_tag user.avatar.variant(resize_to_limit: [100, 100]) %>

<%# Resize to fill dimensions (crop) %>
<%= image_tag user.avatar.variant(resize_to_fill: [100, 100]) %>

<%# Resize and convert format %>
<%= image_tag user.avatar.variant(resize_to_limit: [400, 400], format: :webp) %>

<%# Multiple transformations %>
<%= image_tag user.avatar.variant(
  resize_to_fill: [200, 200],
  rotate: 90,
  saver: { quality: 80 }
) %>
```

### Named Variants

```ruby
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [100, 100]
    attachable.variant :medium, resize_to_limit: [300, 300]
    attachable.variant :large, resize_to_limit: [800, 800]
  end
end
```

```erb
<%= image_tag user.avatar.variant(:thumb) %>
<%= image_tag user.avatar.variant(:medium) %>
```

### Conditional Variants

```ruby
class User < ApplicationRecord
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [100, 100], preprocessed: true
  end
end
```

## Previews (Non-Image Files)

Generate preview images for videos and PDFs:

```erb
<%# Video preview (requires ffmpeg) %>
<%= image_tag message.video.preview(resize_to_limit: [300, 300]) %>

<%# PDF preview (requires poppler or mupdf) %>
<%= image_tag message.document.preview(resize_to_limit: [300, 300]) %>
```

```ruby
# Check if previewable
message.video.previewable?  # => true for video/pdf
message.document.previewable?
```

## File Metadata

```ruby
# Basic metadata
user.avatar.filename      # => "avatar.jpg"
user.avatar.content_type  # => "image/jpeg"
user.avatar.byte_size     # => 12345

# Image-specific (after analysis)
user.avatar.metadata[:width]   # => 800
user.avatar.metadata[:height]  # => 600

# Blob access
user.avatar.blob.created_at
user.avatar.blob.checksum
```

## Eager Loading

Prevent N+1 queries:

```ruby
# Include attachments
User.with_attached_avatar.each do |user|
  url_for(user.avatar)
end

# Multiple attachments
Message.with_attached_images.with_attached_documents

# In scope
class User < ApplicationRecord
  scope :with_avatars, -> { with_attached_avatar }
end
```

## Validation

Active Storage doesn't include built-in validations. Use the `active_storage_validations` gem:

```ruby
# Gemfile
gem "active_storage_validations"
```

```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, attached: true,
    content_type: ["image/png", "image/jpeg"],
    size: { less_than: 5.megabytes }
end

class Message < ApplicationRecord
  has_many_attached :images

  validates :images, limit: { max: 10 },
    content_type: ["image/png", "image/jpeg", "image/gif"],
    size: { less_than: 2.megabytes }
end
```

## Serving Files

### Public URLs (Default)

```ruby
# Redirect to storage service
url_for(user.avatar)
rails_blob_url(user.avatar)

# Download link
rails_blob_path(user.avatar, disposition: "attachment")
```

### Proxy Mode

Serve files through your app (hides storage URLs):

```ruby
# config/environments/production.rb
config.active_storage.resolve_model_to_route = :rails_storage_proxy
```

### Authenticated Access

```ruby
class AttachmentsController < ApplicationController
  before_action :authenticate_user!

  def show
    @attachment = ActiveStorage::Attachment.find(params[:id])

    if authorized?(@attachment)
      redirect_to rails_blob_url(@attachment.blob), allow_other_host: true
    else
      head :forbidden
    end
  end
end
```

## Background Processing

```ruby
# Analyze files in background
config.active_storage.queues.analysis = :low_priority

# Generate variants in background
config.active_storage.queues.transform = :low_priority

# Purge files in background
config.active_storage.queues.purge = :low_priority
```

## Testing

```ruby
class UserTest < ActiveSupport::TestCase
  test "avatar attachment" do
    user = User.new(name: "Test")
    user.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.jpg")),
      filename: "avatar.jpg",
      content_type: "image/jpeg"
    )

    assert user.avatar.attached?
    assert_equal "avatar.jpg", user.avatar.filename.to_s
  end
end

# Clean up test files
class ActiveSupport::TestCase
  teardown do
    ActiveStorage::Blob.where.not(id: ActiveStorage::Attachment.select(:blob_id)).find_each(&:purge)
  end
end
```

## CORS Configuration (S3)

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["PUT"],
    "AllowedOrigins": ["https://example.com"],
    "ExposeHeaders": [],
    "MaxAgeSeconds": 3600
  }
]
```

## Best Practices

1. **Use direct uploads** - Avoid tying up Rails processes with large files
2. **Generate variants lazily** - Don't pre-generate all sizes
3. **Set content types explicitly** - Don't trust user-provided content types
4. **Validate on model** - Check file types and sizes before storage
5. **Clean up unattached blobs** - Run `ActiveStorage::Blob.unattached.where(...).find_each(&:purge)`
6. **Use CDN** - Configure `config.active_storage.service_urls_expire_in` and CDN caching
