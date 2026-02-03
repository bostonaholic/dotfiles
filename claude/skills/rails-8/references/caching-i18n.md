# Caching and Internationalization Reference

## Caching

### Fragment Caching

Cache portions of views:

```erb
<% cache @product do %>
  <article class="product">
    <h2><%= @product.name %></h2>
    <p><%= @product.description %></p>
    <%= image_tag @product.image.variant(:thumb) %>
  </article>
<% end %>
```

### Cache Keys

Rails automatically generates cache keys from:

```ruby
# Model-based (uses updated_at)
cache @product  # => "products/1-20250203143022"

# Array of objects
cache [@user, @product]  # => "users/1-xxx/products/2-yyy"

# Explicit key
cache "sidebar-#{Date.today}" do
  # ...
end

# With version
cache @product, version: "v2" do
  # ...
end
```

### Collection Caching

```erb
<%# Cache each item separately %>
<%= render partial: "products/product", collection: @products, cached: true %>

<%# Equivalent to %>
<% @products.each do |product| %>
  <% cache product do %>
    <%= render product %>
  <% end %>
<% end %>
```

### Russian Doll Caching

Nested caches that auto-expire:

```erb
<% cache @category do %>
  <h2><%= @category.name %></h2>

  <% @category.products.each do |product| %>
    <% cache product do %>
      <%= render product %>
    <% end %>
  <% end %>
<% end %>
```

Touch parent when child updates:

```ruby
class Product < ApplicationRecord
  belongs_to :category, touch: true
end
```

### Low-Level Caching

```ruby
# Read/write with block (most common)
Rails.cache.fetch("stats/#{Date.today}", expires_in: 1.hour) do
  expensive_calculation
end

# Explicit read/write
Rails.cache.write("key", value, expires_in: 1.hour)
value = Rails.cache.read("key")

# Delete
Rails.cache.delete("key")

# Check existence
Rails.cache.exist?("key")

# Increment/decrement
Rails.cache.increment("counter")
Rails.cache.decrement("counter")

# Read multiple
Rails.cache.read_multi("key1", "key2", "key3")

# Write multiple
Rails.cache.write_multi({ "key1" => "value1", "key2" => "value2" })

# Fetch multiple (with block for missing)
Rails.cache.fetch_multi("key1", "key2") do |key|
  compute_value_for(key)
end
```

### Cache Stores

```ruby
# config/environments/production.rb

# Solid Cache (Rails 8 default - database-backed)
config.cache_store = :solid_cache_store

# Memory store (development, single process)
config.cache_store = :memory_store, { size: 64.megabytes }

# File store (simple, multi-process)
config.cache_store = :file_store, Rails.root.join("tmp/cache")

# Memcached
config.cache_store = :mem_cache_store, "cache1.example.com", "cache2.example.com"

# Redis
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }

# Null store (development/testing)
config.cache_store = :null_store
```

### Conditional GET (HTTP Caching)

```ruby
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])

    # Return 304 Not Modified if ETag matches
    if stale?(@product)
      respond_to do |format|
        format.html
        format.json { render json: @product }
      end
    end
  end

  def index
    @products = Product.all

    # With explicit options
    if stale?(etag: @products, last_modified: @products.maximum(:updated_at))
      render :index
    end
  end
end

# Without response body (just check freshness)
class ProductsController < ApplicationController
  def show
    @product = Product.find(params[:id])
    fresh_when(@product)
  end
end
```

### Cache Expiration

```ruby
# Expire on model callback
class Product < ApplicationRecord
  after_commit :expire_cache

  private

  def expire_cache
    Rails.cache.delete("product/#{id}")
    Rails.cache.delete_matched("products/*")
  end
end

# Expire with pattern
Rails.cache.delete_matched("views/products/*")
```

---

## Internationalization (I18n)

### Configuration

```ruby
# config/application.rb
config.i18n.default_locale = :en
config.i18n.available_locales = [:en, :es, :fr, :de]
config.i18n.fallbacks = true
config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
```

### Translation Files

```yaml
# config/locales/en.yml
en:
  hello: "Hello"
  welcome: "Welcome, %{name}!"

  activerecord:
    models:
      user: "User"
      product: "Product"
    attributes:
      user:
        email: "Email Address"
        name: "Full Name"
    errors:
      models:
        user:
          attributes:
            email:
              blank: "is required"
              taken: "is already registered"

  products:
    index:
      title: "All Products"
      empty: "No products found"
    show:
      add_to_cart: "Add to Cart"
      out_of_stock: "Out of Stock"

  helpers:
    submit:
      create: "Create %{model}"
      update: "Update %{model}"

  time:
    formats:
      short: "%b %d"
      long: "%B %d, %Y at %I:%M %p"

  number:
    currency:
      format:
        unit: "$"
        precision: 2
        delimiter: ","
        separator: "."
```

```yaml
# config/locales/es.yml
es:
  hello: "Hola"
  welcome: "¡Bienvenido, %{name}!"

  activerecord:
    models:
      user: "Usuario"
      product: "Producto"
```

### Using Translations

```erb
<%# Basic lookup %>
<%= t("hello") %>
<%= t(:hello) %>

<%# With interpolation %>
<%= t("welcome", name: @user.name) %>

<%# Lazy lookup (scoped to view) %>
<%# In app/views/products/index.html.erb %>
<%= t(".title") %>  <%# Looks up products.index.title %>

<%# With default %>
<%= t("missing.key", default: "Fallback text") %>

<%# HTML safe (key ends in _html) %>
<%= t("welcome_html", name: @user.name) %>

<%# Pluralization %>
<%= t("inbox.message", count: @messages.count) %>
```

```yaml
# Pluralization
en:
  inbox:
    message:
      zero: "No messages"
      one: "1 message"
      other: "%{count} messages"
```

### Setting Locale

```ruby
class ApplicationController < ActionController::Base
  around_action :switch_locale

  private

  def switch_locale(&action)
    locale = extract_locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def extract_locale
    # From URL parameter
    params[:locale] if I18n.available_locales.include?(params[:locale]&.to_sym)
  end
end
```

### URL-Based Locale

```ruby
# config/routes.rb
Rails.application.routes.draw do
  scope "/:locale", locale: /en|es|fr/ do
    resources :products
    root "home#index"
  end

  root "home#index"
end
```

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

### Model Translations

```erb
<%# Automatic lookups for model names %>
<%= User.model_name.human %>  <%# "User" or translated %>
<%= User.human_attribute_name(:email) %>  <%# "Email Address" %>

<%# Error messages %>
<% @user.errors.full_messages.each do |msg| %>
  <%= msg %>  <%# Uses translated attribute names %>
<% end %>
```

### Date/Time Localization

```erb
<%# Use l() helper %>
<%= l(Date.today) %>
<%= l(Time.current) %>
<%= l(Time.current, format: :short) %>
<%= l(Time.current, format: :long) %>

<%# Custom format %>
<%= l(@post.created_at, format: "%A, %B %d") %>
```

```yaml
es:
  date:
    formats:
      default: "%d/%m/%Y"
      short: "%d %b"
      long: "%d de %B de %Y"
    day_names: [Domingo, Lunes, Martes, Miércoles, Jueves, Viernes, Sábado]
    abbr_day_names: [Dom, Lun, Mar, Mié, Jue, Vie, Sáb]
    month_names: [~, Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, Septiembre, Octubre, Noviembre, Diciembre]
    abbr_month_names: [~, Ene, Feb, Mar, Abr, May, Jun, Jul, Ago, Sep, Oct, Nov, Dic]

  time:
    formats:
      default: "%d/%m/%Y %H:%M"
      short: "%d %b %H:%M"
      long: "%d de %B de %Y %H:%M"
```

### Number Localization

```erb
<%= number_to_currency(1234.50) %>  <%# Uses locale's currency format %>
<%= number_to_percentage(75.5) %>
<%= number_with_delimiter(1000000) %>
```

```yaml
es:
  number:
    currency:
      format:
        unit: "€"
        format: "%n %u"  # 1.234,50 €
        precision: 2
        delimiter: "."
        separator: ","
    format:
      delimiter: "."
      separator: ","
```

### Form Labels

```erb
<%= form_with model: @user do |f| %>
  <%= f.label :email %>  <%# Uses human_attribute_name %>
  <%= f.email_field :email %>

  <%= f.submit %>  <%# Uses helpers.submit.create/update %>
<% end %>
```

### Missing Translations

```ruby
# config/environments/development.rb
config.i18n.raise_on_missing_translations = true

# Or custom handler
config.action_view.raise_on_missing_translations = true
```

### Translation Files Organization

```text
config/locales/
├── en.yml                    # Default English
├── es.yml                    # Spanish
├── models/
│   ├── user.en.yml
│   └── user.es.yml
├── views/
│   ├── products.en.yml
│   └── products.es.yml
└── mailers/
    ├── user_mailer.en.yml
    └── user_mailer.es.yml
```

## Best Practices

### Caching Best Practices

1. **Start with fragment caching** - Biggest wins with least effort
2. **Use touch for associations** - Auto-expire nested caches
3. **Cache expensive computations** - Not just views
4. **Monitor cache hit rates** - Ensure caching is effective
5. **Set appropriate TTLs** - Balance freshness with performance

### I18n

1. **Use lazy lookup in views** - `t(".key")` is cleaner and scoped
2. **Keep translations organized** - Mirror app structure
3. **Use YAML anchors** - DRY for repeated translations
4. **Include locale in URLs** - SEO-friendly and shareable
5. **Always use I18n** - Even for single-language apps (future-proofing)
6. **Use _html suffix** - For translations containing HTML
