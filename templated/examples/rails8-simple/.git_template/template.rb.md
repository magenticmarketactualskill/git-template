# Rails8 Simple Template Documentation

Rails 8 Simple Template
A basic template for Rails 8 applications with essential setup
Demonstrates modular generator usage with method calls, parameters, and expected results
Load generator modules for demonstration

## Template Overview

```ruby
require_relative '../../../lib/git_template/template_generators/gem_bundle_generator'
require_relative '../../../lib/git_template/template_generators/view_generator'
require_relative '../../../lib/git_template/template_generators/test_generator'
require_relative '../../../lib/git_template/template_generators/home_feature_generator'
require_relative '../../../lib/git_template/template_generators/post_feature_generator'
require_relative '../../../lib/git_template/template_generators/completion_generator'

say "Applying Rails 8 Simple Template..."

```

## 010_PHASE_RubyVersion

*Ruby version and basic configuration phase*

## 030_PHASE_GemBundle

*Gem bundle configuration*

```ruby
say "#~ 030_PHASE_GemBundle_Development_Test"
say "Adding development and test gems..."

gem_group :development, :test do
  gem 'rspec-rails' unless File.read('Gemfile').include?('rspec-rails')
  gem 'factory_bot_rails'
  gem 'faker'
end

say "#~ 030_PHASE_GemBundle_Development"
say "Adding development gems..."

gem_group :development do
  gem 'annotate' unless File.read('Gemfile').include?('annotate')
  gem 'better_errors'
  gem 'binding_of_caller'
end

```

## 040_PHASE_View

*View and UI configuration*

```ruby
say "#~ 040_PHASE_View_Markup"
say "Updating application layout..."

gsub_file 'app/views/layouts/application.html.erb',
  '<title>Rails8Simple</title>',
  '<title>Rails 8 Simple Application</title>'

say "#~ 040_PHASE_View_Styling"
say "Adding basic styling..."

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

```

## 050_PHASE_Test

*Testing framework setup*

```ruby
say "#~ 050_PHASE_Test"
say "Setting up RSpec testing framework..."

generate 'rspec:install'

```

## 100_PHASE_Feature_Home

*Application feature implementation*

```ruby
say "#~ 100_PHASE_Feature_Home_Controller"
say "Creating welcome controller..."

generate :controller, 'Welcome', 'index'

say "#~ 100_PHASE_Feature_Home_Route"
say "Setting up root route..."

route "root 'welcome#index'"

say "#~ 100_PHASE_Feature_Home_View_Markup"
say "Creating welcome view..."

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

```

## 100_PHASE_Feature_Post

*Application feature implementation*

```ruby
say "#~ 100_PHASE_Feature_Post_Model"
say "Creating Post model..."

generate :model, 'Post', 'title:string', 'content:text', 'published:boolean'

say "#~ 100_PHASE_Feature_Post_Model_Migrate"
say "Running database migrations..."

rails_command 'db:migrate'

say "#~ 100_PHASE_Feature_Post_Model_Seed"
say "Adding sample data..."

append_to_file 'db/seeds.rb', <<~RUBY

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

```

## 900_PHASE_Complete

*Template completion and next steps*

```ruby
say "#~ 900_PHASE_Complete"
say "Template application completed!"

say "Rails 8 Simple Template applied successfully!", :green
say "Next steps:", :blue
say "  1. Start the server: bin/rails server"
say "  2. Visit http://localhost:3000"
say "  3. Customize your application"

```

## Template Phase Structure

This template follows the git-template specialized phase architecture:

- **010_PHASE**: Ruby version and basic configuration
- **030_PHASE**: Gem dependencies and bundler setup
- **040_PHASE**: UI, views, and styling configuration
- **050_PHASE**: Testing framework setup
- **100_PHASE**: Application features and functionality
- **900_PHASE**: Completion messages and next steps

Each phase has a specific responsibility, making the template organized, maintainable, and easy to iterate on during development.