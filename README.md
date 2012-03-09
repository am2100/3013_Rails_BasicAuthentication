# Basic Authentication
These instructions extracted from Ryan Bates [Rails Cast #250 Authentication from Scratch](http://railscasts.com/episodes/250-authentication-from-scratch-revised?autoplay=true).

Thank you Ryan Bates!

Beyond the fact that this works for my Windows XP system, I can offer you no guarantees!

## Add a Signup form for creating a new user record
### Create a User Model / Controller to handle the signup process
Use a resource generator which is similar to a scaffold generator, but doesn't fill in all the controller actions.

password_digest is an important name as it is the default name used with the has_secure_password feature added in Rails 3.1

>\> rails g resource user email password_digest  
>\> rake db:migrate

### Add has_secure_password column to the User model
has_secure_password adds simple authentication support to the User model using a password digest column.

    class User < ActiveRecord::Base
      has_secure_password
    end

### Add bcrypt-ruby to Gemfile
To get has_secure_password working update your Gemfile to include bcrypt-ruby. This handles the hashing of the password to the database:

    # Use ActiveModel has_secure_password
    gem 'bcrypt-ruby', '~> 3.0.0'

>\> bundle install

### Set which attributes the user can set in the User model
If you were to add an admin column to the model, this would prevent the user from setting this through mass assignment.

    attr_accessible :email, :password, :password_confirmation

### Add validations to User model
You don't need to validate the presence of the password or password_confirmation because these are validated by has_secure_password.

    EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i

    validates :email,    uniqueness: true,
			     format: { with: EMAIL_REGEX }
    validates :password,     length: { minimum: 8 }


### Create Sign Up form
#### app/controllers/users_controller.rb
    def new
      @user = User.new
    end

    def create
      @user = User.new(params[:user])
      if @user.save
	session[:user_id] = @user.id # Automatically log the user in on successful Sign Up.
	redirect_to root_url, notice: "Thank you for signing up!"
      else
	render "new"
      end
    end

#### app/views/users/new.html.erb
    <h1>Sign Up</h1>

    <%= form_for @user do |f| %>
      <% if @user.errors.any? %>
	<div class="error_messages">
	  <h2>Form is invalid</h2>
	  <ul>
	    <% @user.errors.full_messages.each do |message| %>
	      <li><%= message %></li>
	    <% end %>
	  </ul>
	</div>
      <% end %>

      <div class="field">
	<%= f.label :email %><br />
	<%= f.text_field :email %>
      </div>
      <div class="field">
	<%= f.label :password %><br />
	<%= f.password_field :password %>
      </div>
      <div class="field">
	<%= f.label :password_confirmation %><br />
	<%= f.password_field :password_confirmation %>
      </div>
      <div class="actions"><%= f.submit "Sign Up" %></div>
    <% end %>

### Create a link to Sign Up form
    <%= link_to 'Sign Up', new_user_path %>

In those circumstances where signing up is a public feature of your site, you may want to use a user_header div for all your login / logout / sign up options..

    <div id="user_header">
      <%= link_to 'Sign Up', new_user_path %>
    </div>

## Create a Login form
### Create Sessions controller
>\> rails g controller sessions new

### Adjust generated routes
#### Add a Sessions resource
    resources :sessions
#### Remove generated route
    get 'sessions/new'

### app/views/sessions/new.html.erb
Notice the use of form_for as we're not working off the model here. We're also using the sessions_path so that the form will trigger the create action in the sessions controller.
    <h1>Log In</h1>

    <%= form_tag sessions_path do %>
      <div class="field">
	<%= label_tag :email %><br />
	<%= text_field_tag :email, params[:email] %>
      </div>
      <div class="field">
	<%= label_tag :password %><br />
	<%= password_field_tag :password %>
      </div>
      <div class="actions"><%= submit_tag "Log In" %></div>
    <% end %>

### app/controllers/sessions_controller.rb
Nb. This is where the actual authentication happens.
The authenticate method is supplied by has_secure_password.

    def new
    end

    def create
      user = User.find_by_email(params[:email])
      if user && user.authenticate(params[:password])
	session[:user_id] = user.id
	redirect_to root_url, notice: "Logged in!"
      else
	flash.now.alert = "Email or password is invalid"
	render "new"
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to root_url, notice: "Logged out!"
    end

### Add Log in link to user_header div in application.html.erb
    <div id="user_header">
      <%= link_to 'Sign Up', new_user_path %> or
      <%= link_to 'Log In', new_session_path %>
    </div>

## Create a status message for logged in users
### Fetch the currently logged in user record
Nb. The current_user method is located in application_controller.rb so
that it is available to all controllers.

Find the currently logged-in users' record using session[:user_id]
which was set when the user logged in, but only if that session
variable exists.

The current_user method may be called many times during a request, so
it is a good idea to cache the current_user record in an instance
variable so that it will only be fetched once per request.

To make the method accessible from inside views as well, user the helper_method.

    private

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
    helper_method :current_user

### Add Status message to user_header div in application.html.erb
Check that a current_user exists. If it does, display the users email address (or username).

    <div id="user_header">
      <% if current_user %>
        Logged in as  <%= current_user.email %>.
      <% else %>
        <%= link_to 'Sign Up', new_user_path %> or
        <%= link_to 'Log In', new_session_path %>
      <% end %>
    </div>

## Create Log Out functionality
### Add a destroy action to the SessionsController

    def destroy
      session[:user_id] = nil
      redirect_to root_url, notice: "Logged out!"
    end

### Add Log out link to user_header div in application.html.erb
Nb. The Log Out session_path expects an id (although it doesn't
actually use the :id parameter), so RB suggests using 'current' as a
sop to that! This issue is rendered moot later on when the example is
amended to use more appropriate custom route names.

Setting the :method to delete triggers the destroy action.

    <div id="user_header">
      <% if current_user %>
        Logged in as  <%= current_user.email %>.
	<%= link_to 'Log Out', session_path('current'), method: 'delete' %>
      <% else %>
        <%= link_to 'Sign Up', new_user_path %> or
        <%= link_to 'Log In', new_session_path %>
      <% end %>
    </div>

## Improve 'Log in', 'Log Out' and 'Sign Up' URL's by adding custom routes
Nb. The logout request is a GET request here, but you could change it
to a DELETE request as technically it is changing the Users
status. However as it doesn't actually modify anything in the
database, it seems OK to leave it as a GET request.

    get 'signup', to: 'users#new', as: 'signup'
    get 'login', to: 'sessions#new', as: 'login'
    get 'logout', to: 'sessions#destroy', as: 'logout'

### Update the layout file to take advantage of new named routes

    <% if current_user %>
      Logged in as <%= current_user.email %>.
      <%= link_to "Log Out", logout_path %>
    <% else %>
      <%= link_to "Sign Up", signup_path %> or
      <%= link_to "Log In", login_path %>
    <% end %>

## Automatically logging a user in when they Sign Up.
### app/controllers/users_controller.rb
Set the session[:user_id] variable to the newly created users :id on
successfully saving a new user.

## Authorizing page access
### Add authorize method to ApplicationController
Nb. This method is now available to all controllers.
If the current_user method returns nil, the user is not logged in.

    def authorize
      redirect_to login_url, alert: "Not authorized" if current_user.nil?
    end

### Add a before filter to controller actions which have restricted access.

    before_filter :authorize, only: [:edit, :update] # or whatever actions are appropriate.

# Final source code
## terminal
>\> rails g resource user email password_digest  
>\> rake db:migrate  
>\> rails g controller sessions new  

## Gemfile
    gem 'bcrypt-ruby', '~> 3.0.0'

## config/routes.rb
    get 'signup', to: 'users#new', as: 'signup'
    get 'login', to: 'sessions#new', as: 'login'
    get 'logout', to: 'sessions#destroy', as: 'logout'

    resources :users
    resources :sessions

## models/user.rb
    has_secure_password

    attr_accessible :email, :password, :password_confirmation

    validates_uniqueness_of :email

## controllers/users_controller.rb
    def new
      @user = User.new
    end

    def create
      @user = User.new(params[:user])
      if @user.save
	session[:user_id] = @user.id
	redirect_to root_url, notice: "Thank you for signing up!"
      else
	render "new"
      end
    end

## controllers/sessions_controller.rb
    def new
    end

    def create
      user = User.find_by_email(params[:email])
      if user && user.authenticate(params[:password])
	session[:user_id] = user.id
	redirect_to root_url, notice: "Logged in!"
      else
	flash.now.alert = "Email or password is invalid"
	render "new"
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to root_url, notice: "Logged out!"
    end

## controllers/application_controller.rb
    private

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
    helper_method :current_user

    def authorize
      redirect_to login_url, alert: "Not authorized" if current_user.nil?
    end

## controllers/secure_page_controller.rb
    before_filter :authorize, only: [:edit, :update]

## views/users/new.html.erb
    <h1>Sign Up</h1>

    <%= form_for @user do |f| %>
      <% if @user.errors.any? %>
	<div class="error_messages">
	  <h2>Form is invalid</h2>
	  <ul>
	    <% @user.errors.full_messages.each do |message| %>
	      <li><%= message %></li>
	    <% end %>
	  </ul>
	</div>
      <% end %>

      <div class="field">
	<%= f.label :email %><br />
	<%= f.text_field :email %>
      </div>
      <div class="field">
	<%= f.label :password %><br />
	<%= f.password_field :password %>
      </div>
      <div class="field">
	<%= f.label :password_confirmation %><br />
	<%= f.password_field :password_confirmation %>
      </div>
      <div class="actions"><%= f.submit "Sign Up" %></div>
    <% end %>

## views/sessions/new.html.erb
    <h1>Log In</h1>

    <%= form_tag sessions_path do %>
      <div class="field">
	<%= label_tag :email %><br />
	<%= text_field_tag :email, params[:email] %>
      </div>
      <div class="field">
	<%= label_tag :password %><br />
	<%= password_field_tag :password %>
      </div>
      <div class="actions"><%= submit_tag "Log In" %></div>
    <% end %>


## views/layouts/application.html.erb
    <% if current_user %>
      Logged in as <%= current_user.email %>.
      <%= link_to "Log Out", logout_path %>
    <% else %>
      <%= link_to "Sign Up", signup_path %> or
      <%= link_to "Log In", login_path %>
    <% end %>

