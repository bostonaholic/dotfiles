# Forms Reference

## form_with (Recommended)

The primary form helper in Rails 8.

### Model-Backed Forms

```erb
<%# New record - POST to /products %>
<%= form_with model: @product do |form| %>
  <%= form.text_field :name %>
  <%= form.submit %>
<% end %>

<%# Existing record - PATCH to /products/:id %>
<%= form_with model: @product do |form| %>
  <%= form.text_field :name %>
  <%= form.submit %>
<% end %>

<%# Namespaced resource %>
<%= form_with model: [:admin, @product] do |form| %>
```

### Non-Model Forms

```erb
<%= form_with url: search_path, method: :get do |form| %>
  <%= form.text_field :query %>
  <%= form.submit "Search" %>
<% end %>
```

### Form Options

```erb
<%= form_with model: @product,
              url: custom_path,
              method: :put,
              local: true,           # Disable Turbo (full page submit)
              data: { turbo: false },
              html: { class: "product-form", id: "main-form" },
              multipart: true do |form| %>
```

## Form Fields

### Text Inputs

```erb
<%= form.text_field :name %>
<%= form.text_field :name, placeholder: "Enter name", class: "form-control" %>

<%= form.email_field :email %>
<%= form.password_field :password %>
<%= form.telephone_field :phone %>
<%= form.url_field :website %>
<%= form.search_field :query %>

<%= form.number_field :quantity, min: 0, max: 100, step: 1 %>
<%= form.range_field :rating, min: 1, max: 5 %>

<%= form.text_area :description, rows: 5, cols: 40 %>
```

### Hidden Fields

```erb
<%= form.hidden_field :user_id %>
<%= form.hidden_field :token, value: @token %>
```

### Checkboxes

```erb
<%# Single checkbox %>
<%= form.check_box :active %>
<%= form.label :active %>

<%# With custom values %>
<%= form.check_box :status, { class: "checkbox" }, "active", "inactive" %>

<%# Collection of checkboxes %>
<%= form.collection_check_boxes :category_ids, Category.all, :id, :name do |b| %>
  <div class="checkbox">
    <%= b.check_box %>
    <%= b.label %>
  </div>
<% end %>
```

### Radio Buttons

```erb
<%# Individual radios %>
<%= form.radio_button :priority, "low" %>
<%= form.label :priority_low, "Low" %>

<%= form.radio_button :priority, "high" %>
<%= form.label :priority_high, "High" %>

<%# Collection %>
<%= form.collection_radio_buttons :status, [["draft", "Draft"], ["published", "Published"]], :first, :last do |b| %>
  <div class="radio">
    <%= b.radio_button %>
    <%= b.label %>
  </div>
<% end %>
```

### Select Boxes

```erb
<%# Basic select %>
<%= form.select :category, ["Books", "Electronics", "Clothing"] %>

<%# With prompt %>
<%= form.select :category, options, prompt: "Select a category" %>

<%# With blank option %>
<%= form.select :category, options, include_blank: true %>

<%# From collection %>
<%= form.collection_select :category_id, Category.all, :id, :name, prompt: "Choose..." %>

<%# Grouped options %>
<%= form.grouped_collection_select :city_id, @countries, :cities, :name, :id, :name %>

<%# Multiple select %>
<%= form.select :tag_ids, Tag.all.pluck(:name, :id), {}, { multiple: true } %>
```

### Date and Time

```erb
<%# Date select (3 dropdowns) %>
<%= form.date_select :published_on %>
<%= form.date_select :published_on, order: [:month, :day, :year] %>

<%# Time select %>
<%= form.time_select :starts_at %>

<%# Combined %>
<%= form.datetime_select :published_at %>

<%# HTML5 inputs %>
<%= form.date_field :published_on %>
<%= form.time_field :starts_at %>
<%= form.datetime_local_field :published_at %>
<%= form.month_field :billing_month %>
<%= form.week_field :week_number %>
```

### File Uploads

```erb
<%# Single file %>
<%= form.file_field :avatar %>

<%# Multiple files %>
<%= form.file_field :images, multiple: true %>

<%# With accept filter %>
<%= form.file_field :document, accept: ".pdf,.doc,.docx" %>

<%# Direct upload (Active Storage) %>
<%= form.file_field :avatar, direct_upload: true %>
```

### Labels

```erb
<%= form.label :name %>
<%= form.label :name, "Full Name" %>
<%= form.label :name, class: "required" do %>
  Name <span class="required">*</span>
<% end %>
```

## Error Display

```erb
<%= form_with model: @product do |form| %>
  <% if @product.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(@product.errors.count, "error") %> prohibited saving:</h2>
      <ul>
        <% @product.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field <%= 'field_with_errors' if @product.errors[:name].any? %>">
    <%= form.label :name %>
    <%= form.text_field :name %>
    <% @product.errors[:name].each do |error| %>
      <span class="error"><%= error %></span>
    <% end %>
  </div>
<% end %>
```

## Nested Forms

### Setup

```ruby
class Order < ApplicationRecord
  has_many :items, dependent: :destroy
  accepts_nested_attributes_for :items,
    allow_destroy: true,
    reject_if: :all_blank
end
```

### Form

```erb
<%= form_with model: @order do |form| %>
  <%= form.text_field :customer_name %>

  <h3>Items</h3>
  <%= form.fields_for :items do |item_form| %>
    <div class="item">
      <%= item_form.text_field :name %>
      <%= item_form.number_field :quantity %>
      <%= item_form.check_box :_destroy %>
      <%= item_form.label :_destroy, "Remove" %>
    </div>
  <% end %>

  <%= form.submit %>
<% end %>
```

### Controller Params

```ruby
def order_params
  params.expect(order: [
    :customer_name,
    items_attributes: [:id, :name, :quantity, :_destroy]
  ])
end
```

### Dynamic Nested Fields (with Stimulus)

```javascript
// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest(".nested-item")
    const destroyField = item.querySelector("input[name*='_destroy']")

    if (destroyField) {
      destroyField.value = "1"
      item.style.display = "none"
    } else {
      item.remove()
    }
  }
}
```

```erb
<div data-controller="nested-form">
  <%= form.fields_for :items do |item_form| %>
    <%= render "item_fields", form: item_form %>
  <% end %>

  <div data-nested-form-target="container"></div>

  <template data-nested-form-target="template">
    <%= form.fields_for :items, Item.new, child_index: "NEW_RECORD" do |item_form| %>
      <%= render "item_fields", form: item_form %>
    <% end %>
  </template>

  <button data-action="click->nested-form#add">Add Item</button>
</div>
```

## Strong Parameters

### Basic

```ruby
def product_params
  params.expect(product: [:name, :price, :description])
end
```

### With Nested Attributes

```ruby
def order_params
  params.expect(order: [
    :customer_name,
    :notes,
    items_attributes: [:id, :product_id, :quantity, :_destroy]
  ])
end
```

### With Arrays

```ruby
def article_params
  params.expect(article: [:title, tag_ids: []])
end
```

### Dynamic Keys

```ruby
def survey_params
  params.expect(survey: [:title, answers: {}])
end
```

## Custom Form Builders

```ruby
# app/helpers/application_helper.rb
class CustomFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(method, options = {})
    @template.content_tag(:div, class: "form-group") do
      label(method, class: "form-label") +
      super(method, options.merge(class: "form-control #{options[:class]}"))
    end
  end

  def submit(value = nil, options = {})
    super(value, options.merge(class: "btn btn-primary #{options[:class]}"))
  end
end
```

```erb
<%= form_with model: @product, builder: CustomFormBuilder do |form| %>
  <%= form.text_field :name %>
  <%= form.submit %>
<% end %>
```

## Turbo Integration

### Turbo Frame Forms

```erb
<%= turbo_frame_tag dom_id(@product) do %>
  <%= form_with model: @product do |form| %>
    <%= form.text_field :name %>
    <%= form.submit %>
  <% end %>
<% end %>
```

### Turbo Stream Responses

```ruby
def create
  @product = Product.new(product_params)

  if @product.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @product }
    end
  else
    render :new, status: :unprocessable_entity
  end
end
```

### Confirmation Dialogs

```erb
<%= form.submit "Delete", data: { turbo_confirm: "Are you sure?" } %>

<%= button_to "Delete", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
```

## Accessibility

```erb
<%= form_with model: @product, html: { "aria-label": "Product form" } do |form| %>
  <div class="field">
    <%= form.label :name %>
    <%= form.text_field :name,
        "aria-required": true,
        "aria-describedby": "name-help" %>
    <p id="name-help" class="help-text">Enter the product name</p>
  </div>

  <% if @product.errors[:name].any? %>
    <%= form.text_field :name,
        "aria-invalid": true,
        "aria-describedby": "name-error" %>
    <p id="name-error" class="error" role="alert">
      <%= @product.errors[:name].first %>
    </p>
  <% end %>
<% end %>
```

## Best Practices

1. **Use form_with** - Modern helper, Turbo-compatible by default
2. **Always use strong parameters** - Security requirement
3. **Display errors clearly** - Near the relevant field
4. **Use labels** - Accessibility requirement
5. **Add aria attributes** - Improve screen reader experience
6. **Validate client-side too** - HTML5 validation attributes
7. **Handle both HTML and Turbo** - `respond_to` for graceful degradation
