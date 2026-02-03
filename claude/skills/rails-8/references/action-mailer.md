# Action Mailer Reference

Action Mailer handles email sending in Rails applications using a pattern similar to controllers.

## Creating Mailers

```bash
bin/rails generate mailer User welcome_email
```

Creates `app/mailers/user_mailer.rb` and view templates.

### Basic Mailer Structure

```ruby
class UserMailer < ApplicationMailer
  default from: "notifications@example.com"

  def welcome_email
    @user = params[:user]
    @url = "http://example.com/login"
    mail(to: @user.email, subject: "Welcome to My Site")
  end

  def password_reset
    @user = params[:user]
    @token = params[:token]
    mail(
      to: @user.email,
      subject: "Password Reset Instructions",
      reply_to: "support@example.com"
    )
  end
end
```

### ApplicationMailer Base

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  before_action :set_common_variables

  private

  def set_common_variables
    @company_name = "My Company"
  end
end
```

## Sending Emails

```ruby
# Asynchronous (recommended for production)
UserMailer.with(user: @user).welcome_email.deliver_later

# Synchronous (blocks until sent)
UserMailer.with(user: @user).welcome_email.deliver_now

# With delay
UserMailer.with(user: @user).welcome_email.deliver_later(wait: 1.hour)
UserMailer.with(user: @user).welcome_email.deliver_later(wait_until: Date.tomorrow.noon)
```

### Multiple Recipients

```ruby
def announcement
  @message = params[:message]
  mail(
    to: ["user1@example.com", "user2@example.com"],
    cc: "manager@example.com",
    bcc: "archive@example.com",
    subject: "Important Announcement"
  )
end
```

### Named Sender

```ruby
def welcome_email
  @user = params[:user]
  mail(
    to: email_address_with_name(@user.email, @user.full_name),
    from: email_address_with_name("noreply@example.com", "My App"),
    subject: "Welcome!"
  )
end
```

## Email Views

Create both HTML and text versions in `app/views/user_mailer/`:

### welcome_email.html.erb

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
  </head>
  <body>
    <h1>Welcome to <%= @company_name %>, <%= @user.name %></h1>
    <p>
      You have successfully signed up. Your username is: <%= @user.email %>.
    </p>
    <p>
      To login, visit: <%= link_to "Login", @url %>
    </p>
    <p>Thanks for joining!</p>
  </body>
</html>
```

### welcome_email.text.erb

```erb
Welcome to <%= @company_name %>, <%= @user.name %>
===============================================

You have successfully signed up. Your username is: <%= @user.email %>.

To login, visit: <%= @url %>

Thanks for joining!
```

## Attachments

### File Attachments

```ruby
def invoice
  @user = params[:user]
  @invoice = params[:invoice]

  # From file
  attachments["invoice.pdf"] = File.read("/path/to/invoice.pdf")

  # With options
  attachments["report.csv"] = {
    mime_type: "text/csv",
    content: generate_csv_content
  }

  mail(to: @user.email, subject: "Your Invoice")
end
```

### Inline Attachments

```ruby
def welcome_email
  @user = params[:user]
  attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo.png")
  mail(to: @user.email, subject: "Welcome")
end
```

In the view:

```erb
<%= image_tag attachments["logo.png"].url, alt: "Company Logo" %>
```

## Layouts

### Email Layout (app/views/layouts/mailer.html.erb)

```erb
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      body { font-family: Arial, sans-serif; }
      .header { background: #333; color: white; padding: 20px; }
      .content { padding: 20px; }
      .footer { background: #eee; padding: 10px; font-size: 12px; }
    </style>
  </head>
  <body>
    <div class="header">
      <%= @company_name %>
    </div>
    <div class="content">
      <%= yield %>
    </div>
    <div class="footer">
      © <%= Date.current.year %> <%= @company_name %>
    </div>
  </body>
</html>
```

### Specifying Layout

```ruby
class UserMailer < ApplicationMailer
  layout "custom_mailer"  # Uses app/views/layouts/custom_mailer.html.erb

  def welcome_email
    mail(to: @user.email, layout: "special")  # Override for single email
  end
end
```

## Callbacks

```ruby
class UserMailer < ApplicationMailer
  before_action :set_user
  before_action :set_unsubscribe_url
  after_action :log_delivery

  after_deliver :record_delivery

  def welcome_email
    mail(to: @user.email, subject: "Welcome!")
  end

  private

  def set_user
    @user = params[:user]
  end

  def set_unsubscribe_url
    @unsubscribe_url = unsubscribe_url(token: @user.unsubscribe_token)
  end

  def log_delivery
    Rails.logger.info "Sending #{action_name} to #{@user.email}"
  end

  def record_delivery
    EmailDelivery.create!(
      mailer: self.class.name,
      action: action_name,
      recipient: @user.email
    )
  end
end
```

## Configuration

### SMTP Settings (config/environments/production.rb)

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.sendgrid.net",
  port: 587,
  domain: "example.com",
  user_name: ENV["SENDGRID_USERNAME"],
  password: ENV["SENDGRID_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true
}

# Required for URL generation in emails
config.action_mailer.default_url_options = { host: "example.com" }
config.action_mailer.asset_host = "https://example.com"
```

### Development Settings

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener  # Opens in browser
# or
config.action_mailer.delivery_method = :file           # Saves to tmp/mails

config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
config.action_mailer.raise_delivery_errors = true
config.action_mailer.perform_caching = false
```

### Test Settings

```ruby
# config/environments/test.rb
config.action_mailer.delivery_method = :test
config.action_mailer.perform_deliveries = true
```

## Previews

Create preview classes in `test/mailers/previews/`:

```ruby
# test/mailers/previews/user_mailer_preview.rb
class UserMailerPreview < ActionMailer::Preview
  def welcome_email
    user = User.first || User.new(name: "Test User", email: "test@example.com")
    UserMailer.with(user: user).welcome_email
  end

  def password_reset
    user = User.first
    UserMailer.with(user: user, token: "abc123").password_reset
  end
end
```

Access at `http://localhost:3000/rails/mailers/user_mailer/welcome_email`

## Interceptors and Observers

### Interceptor (Modify Before Sending)

```ruby
# app/mailers/sandbox_email_interceptor.rb
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ["sandbox@example.com"]
    message.subject = "[SANDBOX] #{message.subject}"
  end
end

# config/initializers/mailer_interceptors.rb
if Rails.env.staging?
  ActionMailer::Base.register_interceptor(SandboxEmailInterceptor)
end
```

### Observer (Track After Sending)

```ruby
# app/mailers/email_delivery_observer.rb
class EmailDeliveryObserver
  def self.delivered_email(message)
    EmailLog.create!(
      to: message.to.join(", "),
      subject: message.subject,
      delivered_at: Time.current
    )
  end
end

# config/initializers/mailer_observers.rb
ActionMailer::Base.register_observer(EmailDeliveryObserver)
```

## Testing

```ruby
class UserMailerTest < ActionMailer::TestCase
  test "welcome email" do
    user = users(:john)
    email = UserMailer.with(user: user).welcome_email

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["noreply@example.com"], email.from
    assert_equal [user.email], email.to
    assert_equal "Welcome to My Site", email.subject
    assert_match user.name, email.body.encoded
  end

  test "welcome email is enqueued" do
    user = users(:john)

    assert_enqueued_emails 1 do
      UserMailer.with(user: user).welcome_email.deliver_later
    end
  end
end
```

## Best Practices

1. **Always use deliver_later** - Avoid blocking requests with synchronous email sending
2. **Provide both HTML and text** - Some clients only display plain text
3. **Use url helpers, not path** - Emails need full URLs (`user_url`, not `user_path`)
4. **Configure asset_host** - Images need absolute URLs in emails
5. **Keep emails simple** - Complex layouts break in email clients
6. **Test with previews** - Visual verification catches formatting issues
7. **Use interceptors in staging** - Prevent accidental emails to real users
