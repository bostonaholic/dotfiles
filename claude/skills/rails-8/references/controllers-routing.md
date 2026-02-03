# Controllers and Routing Reference

## Routing Fundamentals

Routes map HTTP requests to controller actions. Define routes in `config/routes.rb`.

### HTTP Verbs to Actions

| HTTP Verb | Path | Controller#Action | Purpose |
|-----------|------|-------------------|---------|
| GET | /products | products#index | List all |
| GET | /products/new | products#new | New form |
| POST | /products | products#create | Create |
| GET | /products/:id | products#show | Show one |
| GET | /products/:id/edit | products#edit | Edit form |
| PATCH/PUT | /products/:id | products#update | Update |
| DELETE | /products/:id | products#destroy | Delete |

### Resource Routes

```ruby
Rails.application.routes.draw do
  # Full RESTful resource
  resources :products

  # Limited actions
  resources :products, only: [:index, :show]
  resources :products, except: [:destroy]

  # Singular resource (no index, no :id in paths)
  resource :profile

  # Nested resources
  resources :products do
    resources :reviews, only: [:create, :destroy]
  end

  # Shallow nesting (recommended for deep nesting)
  resources :products, shallow: true do
    resources :reviews
  end
end
```

### Member and Collection Routes

```ruby
resources :products do
  member do
    post :publish      # POST /products/:id/publish
    get :preview       # GET /products/:id/preview
  end

  collection do
    get :search        # GET /products/search
    get :featured      # GET /products/featured
  end
end

# Shorthand
resources :products do
  post :publish, on: :member
  get :search, on: :collection
end
```

### Namespaces and Scopes

```ruby
# Namespace: prefixes path, controller path, and helpers
namespace :admin do
  resources :users  # Admin::UsersController, /admin/users, admin_users_path
end

# Scope with module: only changes controller location
scope module: :admin do
  resources :users  # Admin::UsersController, /users, users_path
end

# Scope with path: only changes URL path
scope path: :admin do
  resources :users  # UsersController, /admin/users, users_path
end

# Scope with as: only changes helper names
scope as: :admin do
  resources :users  # UsersController, /users, admin_users_path
end
```

### Custom Routes

```ruby
# Basic routes
get "/about", to: "pages#about"
post "/login", to: "sessions#create"
delete "/logout", to: "sessions#destroy"

# With named route helper
get "/about", to: "pages#about", as: :about  # about_path

# Dynamic segments
get "/products/:id", to: "products#show"
get "/users/:user_id/posts/:id", to: "posts#show"

# Optional segments
get "/products(/:category)", to: "products#index"

# Wildcard segments
get "/files/*path", to: "files#show"  # params[:path]

# Constraints
get "/products/:id", to: "products#show", constraints: { id: /\d+/ }

# Root route
root "home#index"
root "dashboard#index", as: :authenticated_root
```

### Route Constraints

```ruby
# Regex constraints
get "/products/:id", to: "products#show", constraints: { id: /\d+/ }

# Lambda constraints
get "/products/:id", to: "products#show",
    constraints: ->(req) { req.params[:id].to_i > 0 }

# Custom constraint object
class AdminConstraint
  def matches?(request)
    request.session[:admin] == true
  end
end

constraints AdminConstraint.new do
  namespace :admin do
    resources :users
  end
end

# Subdomain constraints
constraints subdomain: "api" do
  resources :products
end
```

### Concerns (DRY Routes)

```ruby
concern :commentable do
  resources :comments, only: [:create, :destroy]
end

concern :imageable do
  resources :images, only: [:create, :destroy]
end

resources :products, concerns: [:commentable, :imageable]
resources :articles, concerns: [:commentable]
```

### Route Helpers

```ruby
# Generated from resources :products
products_path          # /products
products_url           # http://localhost:3000/products
new_product_path       # /products/new
product_path(1)        # /products/1
product_path(@product) # /products/1 (uses to_param)
edit_product_path(1)   # /products/1/edit

# With format
products_path(format: :json)  # /products.json

# With query params
products_path(page: 2, sort: "name")  # /products?page=2&sort=name
```

## Controller Fundamentals

### Basic Controller Structure

```ruby
class ProductsController < ApplicationController
  # Callbacks (filters)
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  after_action :log_activity
  around_action :wrap_in_transaction, only: [:create, :update]

  # Actions
  def index
    @products = Product.all
  end

  def show
    # @product set by before_action
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Deleted successfully."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.expect(product: [:name, :price, :description, :category_id])
  end
end
```

### Strong Parameters

```ruby
# Rails 8 recommended: params.expect
def product_params
  params.expect(product: [:name, :price, :description])
end

# With nested attributes
def order_params
  params.expect(order: [:customer_id, items: [:product_id, :quantity]])
end

# Alternative: params.require.permit
def product_params
  params.require(:product).permit(:name, :price, :description)
end

# Permit all (dangerous, avoid)
params.require(:product).permit!
```

### Rendering Responses

```ruby
# Implicit rendering (renders view matching action name)
def show
  @product = Product.find(params[:id])
  # Renders app/views/products/show.html.erb
end

# Explicit rendering
render :new                           # Render specific template
render "products/show"                # Render from different controller
render template: "products/show"      # Same as above
render plain: "OK"                    # Plain text
render html: "<h1>Hello</h1>".html_safe  # HTML
render json: @product                 # JSON
render xml: @product                  # XML
render inline: "<%= 'Hello' %>"       # Inline ERB
render nothing: true                  # Empty body (deprecated, use head)

# With options
render :show, status: :ok
render :new, status: :unprocessable_entity
render json: @product, status: :created
render :show, layout: "admin"
render :show, layout: false
render :show, formats: [:json]
```

### Redirecting

```ruby
redirect_to products_path
redirect_to @product                  # Uses polymorphic path
redirect_to action: :show, id: 1
redirect_to "https://example.com"
redirect_to :back                     # Previous page (deprecated)
redirect_back fallback_location: root_path

# With flash message
redirect_to @product, notice: "Success"
redirect_to @product, alert: "Warning"
redirect_to @product, flash: { custom: "Message" }

# With status
redirect_to @product, status: :see_other  # 303
redirect_to @product, status: :moved_permanently  # 301
```

### Flash Messages

```ruby
# Set in controller
flash[:notice] = "Success"
flash[:alert] = "Error"
flash[:custom] = "Custom message"

# For current request only
flash.now[:notice] = "For this render"

# Display in view
<% flash.each do |type, message| %>
  <div class="flash <%= type %>"><%= message %></div>
<% end %>
```

### Sessions and Cookies

```ruby
# Sessions (server-side, secure)
session[:user_id] = user.id
current_user_id = session[:user_id]
session.delete(:user_id)
reset_session  # Clear all session data

# Cookies (client-side)
cookies[:remember_token] = "abc123"
cookies[:remember_token] = { value: "abc123", expires: 1.year.from_now }
cookies.permanent[:remember_token] = "abc123"  # 20 years
cookies.signed[:user_id] = 1                   # Tamper-proof
cookies.encrypted[:secret] = "sensitive"       # Encrypted
cookies.delete(:remember_token)
```

### Callbacks (Filters)

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_locale

  private

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end

class ProductsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  after_action :track_view, only: :show
  around_action :catch_exceptions

  private

  def catch_exceptions
    yield
  rescue => e
    logger.error e.message
    redirect_to root_path, alert: "Something went wrong"
  end
end
```

### Request and Response Objects

```ruby
# Request information
request.get?                    # HTTP method
request.post?
request.xhr?                    # AJAX request?
request.format                  # Requested format
request.remote_ip               # Client IP
request.user_agent              # Browser info
request.headers["Authorization"]
request.query_parameters        # Query string params
request.request_parameters      # POST body params
request.path                    # URL path
request.url                     # Full URL
request.host                    # Hostname
request.subdomain               # Subdomain

# Response manipulation
response.status = 404
response.headers["X-Custom"] = "value"
response.body = "Custom body"
```

### Streaming and Downloads

```ruby
# Send file
send_file "/path/to/file.pdf"
send_file "/path/to/file.pdf", filename: "report.pdf", type: "application/pdf"

# Send data
send_data generate_pdf, filename: "report.pdf", type: "application/pdf"

# Streaming
response.headers["Content-Type"] = "text/event-stream"
response.headers["Cache-Control"] = "no-cache"
self.response_body = Enumerator.new do |yielder|
  loop do
    yielder << "data: #{Time.now}\n\n"
    sleep 1
  end
end
```

## API Controllers

```ruby
class Api::V1::ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token  # If using token auth
  before_action :authenticate_api_user!

  def index
    @products = Product.all
    render json: @products
  end

  def show
    @product = Product.find(params[:id])
    render json: @product
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_api_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_user = User.find_by(api_token: token)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def product_params
    params.expect(product: [:name, :price])
  end
end
```
