# Simple Rails Application Template
# Based on https://edgeguides.rubyonrails.org/rails_application_templates.html
#
# Usage:
#   rails new myapp -m template.rb
#   bin/rails app:template LOCATION=template.rb (for existing apps)

def source_paths
  [__dir__]
end

# Helper method to check if a gem already exists in the Gemfile
def gem_exists?(gem_name)
  gemfile_content = File.read("Gemfile")
  gemfile_content.match?(/^\s*gem\s+["']#{Regexp.escape(gem_name)}["']/)
end

# Display welcome message
say "=" * 60
say "Simple Rails Application Template"
say "=" * 60
say ""
say "This template will enhance your Rails application with:"
say "  • Essential gems for development and testing"
say "  • Basic authentication setup"
say "  • Simple home page"
say "  • Code quality tools"
say ""

# Ask user for configuration preferences (or use environment variables for non-interactive mode)
if ENV["RAILS_TEMPLATE_NON_INTERACTIVE"] == "true"
  @use_authentication = ENV["TEMPLATE_USE_AUTHENTICATION"] == "true"
  @use_bootstrap = ENV["TEMPLATE_USE_BOOTSTRAP"] == "true"
  @setup_testing = ENV["TEMPLATE_SETUP_TESTING"] == "true"
  
  say "Running in non-interactive mode with:"
  say "  • Authentication: #{@use_authentication}"
  say "  • Bootstrap: #{@use_bootstrap}"
  say "  • Testing: #{@setup_testing}"
else
  @use_authentication = yes?("Add authentication with Devise?")
  @use_bootstrap = yes?("Add Bootstrap for styling?")
  @setup_testing = yes?("Setup RSpec for testing?")
end

say "\nStarting template application...\n", :green

# Add essential gems
say "Adding essential gems...", :green

# Development and test gems - only add if not already present
gem "debug", platforms: %i[ mri windows ], group: [:development, :test] unless gem_exists?("debug")

if @setup_testing
  gem "rspec-rails", group: [:development, :test] unless gem_exists?("rspec-rails")
  gem "factory_bot_rails", group: [:development, :test] unless gem_exists?("factory_bot_rails")
  gem "faker", group: [:development, :test] unless gem_exists?("faker")
end

# Only add web-console if not already present
gem "web-console", group: :development unless gem_exists?("web-console")

# Add authentication if requested
if @use_authentication
  gem "devise" unless gem_exists?("devise")
end

# Add Bootstrap if requested
if @use_bootstrap
  gem "bootstrap", "~> 5.3" unless gem_exists?("bootstrap")
  gem "sassc-rails" unless gem_exists?("sassc-rails")
end

# Run bundle install
run "bundle install"

# Setup authentication
if @use_authentication
  say "Setting up Devise authentication...", :green
  generate "devise:install"
  generate "devise", "User"
  
  # Add authentication to application controller
  inject_into_class "app/controllers/application_controller.rb", "ApplicationController" do
    "  before_action :authenticate_user!\n"
  end
end

# Setup testing
if @setup_testing
  say "Setting up RSpec...", :green
  generate "rspec:install"
  
  # Create a simple model spec
  create_file "spec/models/user_spec.rb", <<~RUBY
    require 'rails_helper'

    RSpec.describe User, type: :model do
      it "is valid with valid attributes" do
        user = User.new(email: "test@example.com", password: "password")
        expect(user).to be_valid
      end
    end
  RUBY
end

# Create a simple home controller and view
say "Creating home page...", :green

generate :controller, "Home", "index", "--skip-routes"

# Add route
route "root 'home#index'"

# Create a simple home page
create_file "app/views/home/index.html.erb", <<~HTML
  <div class="container mt-5">
    <div class="row justify-content-center">
      <div class="col-md-8">
        <div class="card">
          <div class="card-header">
            <h1 class="mb-0">Welcome to Your Rails App!</h1>
          </div>
          <div class="card-body">
            <p class="lead">Your Rails application has been successfully created with the simple template.</p>
            
            <h3>What's included:</h3>
            <ul>
              <li>✅ Basic Rails application structure</li>
              <% if defined?(Devise) %>
                <li>✅ User authentication with Devise</li>
              <% end %>
              <% if defined?(Bootstrap) %>
                <li>✅ Bootstrap styling</li>
              <% end %>
              <% if File.exist?(Rails.root.join('spec')) %>
                <li>✅ RSpec testing framework</li>
              <% end %>
              <li>✅ Home page (this page!)</li>
            </ul>
            
            <div class="mt-4">
              <% if defined?(Devise) %>
                <% if user_signed_in? %>
                  <p>Hello, <%= current_user.email %>!</p>
                  <%= link_to "Sign out", destroy_user_session_path, method: :delete, class: "btn btn-outline-secondary" %>
                <% else %>
                  <%= link_to "Sign up", new_user_registration_path, class: "btn btn-primary me-2" %>
                  <%= link_to "Sign in", new_user_session_path, class: "btn btn-outline-primary" %>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
HTML

# Setup Bootstrap if requested
if @use_bootstrap
  say "Setting up Bootstrap...", :green
  
  # Add Bootstrap to application.scss
  create_file "app/assets/stylesheets/application.scss", <<~SCSS
    @import "bootstrap";
    
    body {
      background-color: #f8f9fa;
    }
    
    .card {
      box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
    }
  SCSS
  
  # Remove the original application.css
  remove_file "app/assets/stylesheets/application.css"
  
  # Update application layout to include Bootstrap
  gsub_file "app/views/layouts/application.html.erb", 
    '<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>', 
    '<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>'
end

# Create a simple README
create_file "README_TEMPLATE.md", <<~MARKDOWN
  # Simple Rails Application

  This Rails application was created using the Simple Rails Template.

  ## Features

  - Basic Rails 8 application
  #{@use_authentication ? "- User authentication with Devise" : ""}
  #{@use_bootstrap ? "- Bootstrap styling" : ""}
  #{@setup_testing ? "- RSpec testing framework" : ""}
  - Simple home page

  ## Getting Started

  1. Install dependencies:
     ```bash
     bundle install
     ```

  2. Setup the database:
     ```bash
     rails db:create
     rails db:migrate
     ```

  3. Start the server:
     ```bash
     rails server
     ```

  4. Visit http://localhost:3000

  ## Testing

  #{@setup_testing ? "Run tests with: `bundle exec rspec`" : "No testing framework configured."}

  ## Next Steps

  - Add your models, controllers, and views
  - Customize the styling
  - Add more features as needed

  Happy coding! 🚀
MARKDOWN

# After bundle tasks
after_bundle do
  say "\n" + "=" * 60
  say "Post-Installation Tasks"
  say "=" * 60 + "\n"
  
  # Setup database
  say "Setting up database...", :green
  rails_command "db:create"
  rails_command "db:migrate" if @use_authentication
  
  # Initialize git repository
  if ENV["RAILS_TEMPLATE_NON_INTERACTIVE"] != "true" && yes?("Initialize git repository?")
    git :init
    git add: "."
    git commit: "-m 'Initial commit: Simple Rails application'"
  end
  
  # Display completion message
  say "\n" + "=" * 60
  say "Installation Complete!"
  say "=" * 60 + "\n"
  
  say "Your simple Rails application is ready!", :green
  say ""
  say "Next steps:"
  say "  1. Start the development server:"
  say "     rails server"
  say ""
  say "  2. Visit http://localhost:3000"
  say ""
  
  if @setup_testing
    say "  3. Run tests:"
    say "     bundle exec rspec"
    say ""
  end
  
  say "Happy coding! 🚀", :green
  say ""
end