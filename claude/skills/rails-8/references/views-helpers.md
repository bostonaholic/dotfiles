# Views and Helpers Reference

## Layouts

### Application Layout (app/views/layouts/application.html.erb)

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "My App" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
    <%= yield :head %>
  </head>

  <body class="<%= controller_name %> <%= action_name %>">
    <%= render "shared/header" %>
    <%= render "shared/flash" %>

    <main>
      <%= yield %>
    </main>

    <%= render "shared/footer" %>
    <%= yield :end_of_body %>
  </body>
</html>
```

### Controller-Specific Layouts

```ruby
class AdminController < ApplicationController
  layout "admin"
end

class ProductsController < ApplicationController
  layout "store", only: [:index, :show]
  layout :determine_layout

  private

  def determine_layout
    current_user&.admin? ? "admin" : "application"
  end
end
```

### Conditional Layouts

```ruby
class ArticlesController < ApplicationController
  layout false, only: [:preview]  # No layout
  layout proc { |c| c.request.xhr? ? false : "application" }
end
```

## Content Regions

### yield and content_for

```erb
<%# In layout %>
<head>
  <%= yield :head %>
</head>
<body>
  <aside><%= yield :sidebar %></aside>
  <main><%= yield %></main>
</body>

<%# In view %>
<% content_for :head do %>
  <%= stylesheet_link_tag "articles" %>
<% end %>

<% content_for :sidebar do %>
  <%= render "shared/article_navigation" %>
<% end %>

<h1>Article Content Here</h1>
```

### content_for with Default

```erb
<%# In layout %>
<title><%= content_for(:title) || "Default Title" %></title>

<%# In view %>
<% content_for :title, "My Page Title" %>
```

### provide (Single Assignment)

```erb
<%# Only first call wins %>
<% provide :title, "First Title" %>
<% provide :title, "Second Title" %>  <%# Ignored %>
```

## Partials

### Basic Partial

```erb
<%# app/views/products/_product.html.erb %>
<article class="product" id="<%= dom_id(product) %>">
  <h2><%= product.name %></h2>
  <p><%= product.description %></p>
  <span class="price"><%= number_to_currency(product.price) %></span>
</article>

<%# Rendering %>
<%= render "product", product: @product %>
<%= render partial: "product", locals: { product: @product } %>
```

### Collection Rendering

```erb
<%# Long form %>
<%= render partial: "product", collection: @products %>

<%# Short form (infers partial name from model) %>
<%= render @products %>

<%# With spacer template %>
<%= render @products, spacer_template: "product_divider" %>

<%# Counter variable (product_counter) %>
<article>
  <%= product_counter + 1 %>. <%= product.name %>
</article>
```

### Partial with Layout

```erb
<%= render partial: "product", layout: "product_wrapper", locals: { product: @product } %>

<%# _product_wrapper.html.erb %>
<div class="product-wrapper">
  <%= yield %>
</div>
```

### Shared Partials

```erb
<%# app/views/shared/_error_messages.html.erb %>
<% if object.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(object.errors.count, "error") %> prohibited saving:</h2>
    <ul>
      <% object.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<%# Usage %>
<%= render "shared/error_messages", object: @user %>
```

## ERB Syntax

```erb
<%# Comment - not rendered %>

<% code %>          <%# Execute Ruby, no output %>
<%= expression %>   <%# Execute and output (escaped) %>
<%== expression %>  <%# Execute and output (raw, unescaped) %>

<%- code -%>        <%# Suppress leading/trailing whitespace %>
```

## View Helpers

### Link Helpers

```erb
<%= link_to "Home", root_path %>
<%= link_to "Product", product_path(@product) %>
<%= link_to "Product", @product %>  <%# Polymorphic %>

<%# With options %>
<%= link_to "Delete", @product, method: :delete, data: { turbo_confirm: "Sure?" } %>
<%= link_to "External", "https://example.com", target: "_blank", rel: "noopener" %>

<%# With block %>
<%= link_to product_path(@product) do %>
  <span class="icon">🛒</span>
  <span><%= @product.name %></span>
<% end %>

<%# Button (form-based) %>
<%= button_to "Delete", @product, method: :delete %>
<%= button_to "Add to Cart", cart_items_path, params: { product_id: @product.id } %>
```

### URL Helpers

```erb
<%= products_path %>           <%# /products %>
<%= products_url %>            <%# http://example.com/products %>
<%= product_path(@product) %>  <%# /products/1 %>
<%= edit_product_path(@product) %>
<%= new_product_path %>

<%# With query params %>
<%= products_path(sort: "name", page: 2) %>  <%# /products?sort=name&page=2 %>
```

### Number Helpers

```erb
<%= number_to_currency(1234.56) %>           <%# $1,234.56 %>
<%= number_to_currency(1234, unit: "€") %>   <%# €1,234.00 %>
<%= number_to_percentage(75.5) %>            <%# 75.500% %>
<%= number_to_percentage(75.5, precision: 0) %>  <%# 76% %>
<%= number_with_delimiter(12345678) %>       <%# 12,345,678 %>
<%= number_to_human(1234567890) %>           <%# 1.23 Billion %>
<%= number_to_human_size(1234567) %>         <%# 1.18 MB %>
<%= number_to_phone(5551234567) %>           <%# 555-123-4567 %>
```

### Text Helpers

```erb
<%= truncate("Long text here", length: 20) %>    <%# Long text here... %>
<%= truncate("Long text", length: 15, omission: " (more)") %>

<%= pluralize(1, "person") %>   <%# 1 person %>
<%= pluralize(5, "person") %>   <%# 5 people %>

<%= excerpt("Rails is great", "great", radius: 5) %>  <%# ...is great %>

<%= simple_format("Line 1\n\nLine 2") %>
<%# <p>Line 1</p>\n\n<p>Line 2</p> %>

<%= word_wrap("Long text", line_width: 30) %>
```

### Date/Time Helpers

```erb
<%= time_ago_in_words(3.hours.ago) %>     <%# about 3 hours %>
<%= distance_of_time_in_words(Time.current, 1.day.from_now) %>  <%# 1 day %>

<%= l(Date.today) %>                       <%# Uses I18n %>
<%= l(Time.current, format: :short) %>     <%# 03 Feb 14:30 %>
<%= l(Time.current, format: :long) %>      <%# February 03, 2025 14:30 %>
```

### Tag Helpers

```erb
<%= tag.div class: "container" do %>
  <%= tag.p "Hello", id: "greeting" %>
<% end %>

<%= tag.input type: "text", name: "query", value: params[:q] %>
<%= tag.br %>

<%# Data attributes %>
<%= tag.div data: { controller: "modal", action: "click->modal#open" } %>
<%# <div data-controller="modal" data-action="click->modal#open"></div> %>
```

### Asset Helpers

```erb
<%= image_tag "logo.png", alt: "Company Logo", class: "logo" %>
<%= image_tag "photo.jpg", size: "100x100" %>

<%= stylesheet_link_tag "application", media: "all" %>
<%= javascript_include_tag "application" %>

<%= favicon_link_tag "favicon.ico" %>

<%= video_tag "intro.mp4", controls: true, autoplay: false %>
<%= audio_tag "song.mp3", controls: true %>
```

### Sanitize Helpers

```erb
<%# Remove dangerous HTML %>
<%= sanitize @user.bio %>
<%= sanitize @user.bio, tags: %w[p br strong em], attributes: %w[class id] %>

<%# Strip all tags %>
<%= strip_tags @user.bio %>

<%# Strip links only %>
<%= strip_links @user.bio %>
```

## Custom Helpers

### Application Helper

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def page_title(title = nil)
    base = "My App"
    title.present? ? "#{title} | #{base}" : base
  end

  def active_link_to(text, path, **options)
    classes = [options.delete(:class)]
    classes << "active" if current_page?(path)
    link_to text, path, class: classes.compact.join(" "), **options
  end

  def format_date(date, format = :long)
    return "N/A" if date.blank?
    l(date, format: format)
  end

  def avatar_for(user, size: 40)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_fill: [size, size]),
                class: "avatar",
                alt: user.name
    else
      image_tag "default_avatar.png",
                size: "#{size}x#{size}",
                class: "avatar",
                alt: user.name
    end
  end
end
```

### Model-Specific Helpers

```ruby
# app/helpers/products_helper.rb
module ProductsHelper
  def product_status_badge(product)
    status_class = case product.status
                   when "available" then "badge-success"
                   when "sold_out" then "badge-danger"
                   else "badge-secondary"
                   end

    tag.span product.status.humanize, class: "badge #{status_class}"
  end

  def price_display(product)
    if product.on_sale?
      tag.span(class: "price on-sale") do
        tag.del(number_to_currency(product.original_price)) +
        tag.ins(number_to_currency(product.sale_price))
      end
    else
      tag.span number_to_currency(product.price), class: "price"
    end
  end
end
```

## View Components (Optional Pattern)

For complex view logic, consider ViewComponent gem:

```ruby
# app/components/button_component.rb
class ButtonComponent < ViewComponent::Base
  def initialize(text:, variant: :primary, size: :medium)
    @text = text
    @variant = variant
    @size = size
  end

  def css_class
    "btn btn-#{@variant} btn-#{@size}"
  end
end
```

```erb
<%# app/components/button_component.html.erb %>
<button class="<%= css_class %>">
  <%= @text %>
</button>

<%# Usage %>
<%= render ButtonComponent.new(text: "Submit", variant: :success) %>
```

## Best Practices

1. **Keep views simple** - Move complex logic to helpers or presenters
2. **Use partials for reuse** - Don't repeat view code
3. **Prefer content_for over instance variables** - For layout regions
4. **Use I18n for text** - Even if single language now
5. **Escape user input** - Default `<%= %>` escapes; use `raw` sparingly
6. **Name partials descriptively** - `_form`, `_card`, `_list_item`
7. **Use dom_id helper** - For consistent, unique element IDs
