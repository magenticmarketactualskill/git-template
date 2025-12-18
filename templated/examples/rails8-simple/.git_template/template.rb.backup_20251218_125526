# Rails 8 Simple Template
# A basic template for Rails 8 applications with essential setup
# Demonstrates modular generator usage with method calls, parameters, and expected results

# Load generator modules for demonstration
require_relative '../../../lib/git_template/template_generators/gem_bundle_generator'
require_relative '../../../lib/git_template/template_generators/view_generator'
require_relative '../../../lib/git_template/template_generators/test_generator'
require_relative '../../../lib/git_template/template_generators/home_feature_generator'
require_relative '../../../lib/git_template/template_generators/post_feature_generator'
require_relative '../../../lib/git_template/template_generators/completion_generator'

say "Applying Rails 8 Simple Template..."

#~ 010_PHASE_RubyVersion
# Ruby version configuration (handled by Rails application setup)
# Module: N/A - handled by Rails application initialization
# Method: N/A
# Parameters: N/A
# Expected Result: Ruby version set in .ruby-version file

#~ 030_PHASE_GemBundle
# Module Usage: GitTemplate::TemplateGenerators::GemBundleGenerator
# Method: execute()
# Parameters: none
# Expected Result: Adds development and test gems to Gemfile

# Actual template output equivalent to: GitTemplate::TemplateGenerators::GemBundleGenerator.execute
say "#~ 030_PHASE_GemBundle_Development_Test"
say "Adding development and test gems..."
# Output: Adds gem_group :development, :test block with rspec-rails, factory_bot_rails, faker

gem_group :development, :test do
  gem 'rspec-rails' unless File.read('Gemfile').include?('rspec-rails')
  gem 'factory_bot_rails'
  gem 'faker'
end

say "#~ 030_PHASE_GemBundle_Development"
say "Adding development gems..."
# Output: Adds gem_group :development block with annotate, better_errors, binding_of_caller

gem_group :development do
  gem 'annotate' unless File.read('Gemfile').include?('annotate')
  gem 'better_errors'
  gem 'binding_of_caller'
end

#~ 040_PHASE_View
# Module Usage: GitTemplate::TemplateGenerators::ViewGenerator
# Method: execute()
# Parameters: none
# Expected Result: Updates application layout title and adds CSS styling

# Actual template output equivalent to: GitTemplate::TemplateGenerators::ViewGenerator.execute
say "#~ 040_PHASE_View_Markup"
say "Updating application layout..."
# Output: Replaces title in app/views/layouts/application.html.erb

gsub_file 'app/views/layouts/application.html.erb', 
  '<title>Rails8Simple</title>', 
  '<title>Rails 8 Simple Application</title>'

say "#~ 040_PHASE_View_Styling"
say "Adding basic styling..."
# Output: Appends CSS styles to app/assets/stylesheets/application.css

append_to_file 'app/assets/stylesheets/application.css', <<~CSS

  /* Basic styling for Rails 8 Simple */
  .welcome {
    max-width: 800px;
    margin: 2rem auto;
    padding: 2rem;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }
  
  .welcome h1 {
    color: #2563eb;
    border-bottom: 2px solid #e5e7eb;
    padding-bottom: 0.5rem;
  }
  
  .welcome h2 {
    color: #374151;
    margin-top: 2rem;
  }
  
  .welcome ul {
    background: #f9fafb;
    padding: 1rem;
    border-radius: 0.5rem;
    border-left: 4px solid #2563eb;
  }
CSS

#~ 050_PHASE_Test
# Module Usage: GitTemplate::TemplateGenerators::TestGenerator
# Method: execute()
# Parameters: none
# Expected Result: Installs and configures RSpec testing framework

# Actual template output equivalent to: GitTemplate::TemplateGenerators::TestGenerator.execute
say "#~ 050_PHASE_Test"
say "Setting up RSpec testing framework..."
# Output: Runs 'rails generate rspec:install' to create spec/ directory and configuration

generate 'rspec:install'

#~ 100_PHASE_Feature_Home
# Module Usage: GitTemplate::TemplateGenerators::HomeFeatureGenerator
# Method: execute()
# Parameters: none
# Expected Result: Creates Welcome controller, sets root route, creates welcome view

# Actual template output equivalent to: GitTemplate::TemplateGenerators::HomeFeatureGenerator.execute
say "#~ 100_PHASE_Feature_Home_Controller"
say "Creating welcome controller..."
# Output: Runs 'rails generate controller Welcome index' creating controller, view, helper, assets

generate :controller, 'Welcome', 'index'

say "#~ 100_PHASE_Feature_Home_Route"
say "Setting up root route..."
# Output: Adds "root 'welcome#index'" to config/routes.rb

route "root 'welcome#index'"

say "#~ 100_PHASE_Feature_Home_View_Markup"
say "Creating welcome view..."
# Output: Creates app/views/welcome/index.html.erb with welcome content

create_file 'app/views/welcome/index.html.erb', <<~HTML
  <div class="welcome">
    <h1>Welcome to Rails 8 Simple</h1>
    <p>This is a simple Rails 8 application created with git-template.</p>
    
    <h2>Features</h2>
    <ul>
      <li>Rails 8.0</li>
      <li>RSpec for testing</li>
      <li>Basic MVC structure</li>
      <li>Git-template integration</li>
    </ul>
    
    <h2>Next Steps</h2>
    <p>Start building your application by adding models, views, and controllers.</p>
  </div>
HTML

#~ 100_PHASE_Feature_Post
# Module Usage: GitTemplate::TemplateGenerators::PostFeatureGenerator
# Method: execute()
# Parameters: none
# Expected Result: Creates Post model, runs migrations, adds sample seed data

# Actual template output equivalent to: GitTemplate::TemplateGenerators::PostFeatureGenerator.execute
say "#~ 100_PHASE_Feature_Post_Model"
say "Creating Post model..."
# Output: Runs 'rails generate model Post title:string content:text published:boolean'
# Creates: app/models/post.rb, db/migrate/xxx_create_posts.rb, spec/models/post_spec.rb

generate :model, 'Post', 'title:string', 'content:text', 'published:boolean'

say "#~ 100_PHASE_Feature_Post_Model_Migrate"
say "Running database migrations..."
# Output: Runs 'rails db:migrate' to create posts table in database

rails_command 'db:migrate'

say "#~ 100_PHASE_Feature_Post_Model_Seed"
say "Adding sample data..."
# Output: Appends sample Post records to db/seeds.rb and runs 'rails db:seed'

append_to_file 'db/seeds.rb', <<~RUBY

# Sample data for Rails 8 Simple
Post.create!([
  {
    title: "Welcome to Rails 8",
    content: "This is your first post in the Rails 8 Simple application.",
    published: true
  },
  {
    title: "Getting Started",
    content: "Start building your application by customizing this template.",
    published: true
  }
])
RUBY

rails_command 'db:seed'

#~ 900_PHASE_Complete
# Module Usage: GitTemplate::TemplateGenerators::CompletionGenerator
# Method: execute()
# Parameters: none
# Expected Result: Displays completion messages and next steps for user

# Actual template output equivalent to: GitTemplate::TemplateGenerators::CompletionGenerator.execute
say "#~ 900_PHASE_Complete"
say "Template application completed!"
# Output: Displays success message and next steps in green/blue colors

say "Rails 8 Simple Template applied successfully!", :green
say "Next steps:", :blue
say "  1. Start the server: bin/rails server"
say "  2. Visit http://localhost:3000"
say "  3. Customize your application"

# GENERATOR MODULE SUMMARY:
# =========================
# This template demonstrates how each phase can be extracted into reusable generator modules:
#
# 1. GemBundleGenerator.execute() -> Adds development/test gems to Gemfile
# 2. ViewGenerator.execute() -> Updates layout title and adds CSS styling  
# 3. TestGenerator.execute() -> Installs RSpec testing framework
# 4. HomeFeatureGenerator.execute() -> Creates Welcome controller, route, and view
# 5. PostFeatureGenerator.execute() -> Creates Post model with migrations and seeds
# 6. CompletionGenerator.execute() -> Shows completion messages and next steps
#
# Each generator module encapsulates specific functionality and can be:
# - Used independently in other templates
# - Combined in different ways for various application types
# - Extended with additional parameters and options
# - Tested in isolation for reliability
#
# The modular approach provides better organization, reusability, and maintainability
# compared to monolithic template files.