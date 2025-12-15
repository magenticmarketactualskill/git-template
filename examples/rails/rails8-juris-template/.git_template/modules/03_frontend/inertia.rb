# Setup Inertia.js for Rails integration
say "Setting up Inertia.js...", :green

# Inertia gem already added in gems.rb

# Create Inertia controller concern
file "app/controllers/concerns/inertia_csrf.rb", <<~RUBY
  # Inertia CSRF protection
  module InertiaCsrf
    extend ActiveSupport::Concern

    included do
      before_action :set_inertia_csrf_token
    end

    private

    def set_inertia_csrf_token
      cookies['XSRF-TOKEN'] = form_authenticity_token
    end
  end
RUBY

# Update ApplicationController to include Inertia
file "app/controllers/application_controller.rb", <<~RUBY
  class ApplicationController < ActionController::Base
    include InertiaCsrf
    inertia_share auth: -> {
      {
        user: current_user&.as_json(only: [:id, :email, :name])
      }
    }
  end
RUBY

# Create Inertia initializer
initializer "inertia_rails.rb", <<~RUBY
  # Inertia.js configuration
  InertiaRails.configure do |config|
    # Set the default version
    config.version = ViteRuby.digest
    
    # Configure SSR (Server-Side Rendering) - optional
    # config.ssr_enabled = true
    # config.ssr_url = 'http://localhost:13714'
  end
RUBY

# Create root layout for Inertia
file "app/views/layouts/application.html.erb", <<~ERB
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= content_for(:title) || "Rails8Juris" %></title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      
      <%= vite_client_tag %>
      <%= vite_stylesheet_tag 'application' %>
    </head>

    <body>
      <%= yield %>
      <%= vite_javascript_tag 'application' %>
    </body>
  </html>
ERB

# Create Inertia-specific layout
file "app/views/layouts/inertia.html.erb", <<~ERB
  <!DOCTYPE html>
  <html>
    <head>
      <title><%= content_for(:title) || "Rails8Juris" %></title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <%= csrf_meta_tags %>
      <%= csp_meta_tag %>
      
      <%= vite_client_tag %>
      <%= vite_stylesheet_tag 'application' %>
    </head>

    <body>
      <%= inertia %>
      <%= vite_javascript_tag 'application' %>
    </body>
  </html>
ERB

say "✓ Inertia.js configured", :green
