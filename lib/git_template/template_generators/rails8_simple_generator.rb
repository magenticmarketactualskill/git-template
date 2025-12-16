require 'rails/generators'
require_relative '../template_generator_base'

module GitTemplate
  module TemplateGenerators
    class Rails8SimpleGenerator < TemplateGeneratorBase
      desc "Generate a Rails 8 Simple application setup"
      
      def add_gems
        say_status_with_phase("030_PHASE_GemBundle_Development_Test", "Adding development and test gems...")
        
        gem_group :development, :test do
          add_gem_unless_exists 'rspec-rails'
          gem 'factory_bot_rails'
          gem 'faker'
        end
        
        say_status_with_phase("030_PHASE_GemBundle_Development", "Adding development gems...")
        
        gem_group :development do
          add_gem_unless_exists 'annotate'
          gem 'better_errors'
          gem 'binding_of_caller'
        end
      end
      
      def configure_views
        say_status_with_phase("040_PHASE_View_Markup", "Updating application layout...")
        
        gsub_file 'app/views/layouts/application.html.erb', 
          '<title>Rails8Simple</title>', 
          '<title>Rails 8 Simple Application</title>'
        
        say_status_with_phase("040_PHASE_View_Styling", "Adding basic styling...")
        
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
      end
      
      def setup_testing
        say_status_with_phase("050_PHASE_Test", "Setting up RSpec testing framework...")
        
        generate 'rspec:install'
      end
      
      def create_home_feature
        say_status_with_phase("100_PHASE_Feature_Home_Controller", "Creating welcome controller...")
        
        generate :controller, 'Welcome', 'index'
        
        say_status_with_phase("100_PHASE_Feature_Home_Route", "Setting up root route...")
        
        route "root 'welcome#index'"
        
        say_status_with_phase("100_PHASE_Feature_Home_View_Markup", "Creating welcome view...")
        
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
      end
      
      def create_post_feature
        say_status_with_phase("100_PHASE_Feature_Post_Model", "Creating Post model...")
        
        generate :model, 'Post', 'title:string', 'content:text', 'published:boolean'
        
        say_status_with_phase("100_PHASE_Feature_Post_Model_Migrate", "Running database migrations...")
        
        rails_command 'db:migrate'
        
        say_status_with_phase("100_PHASE_Feature_Post_Model_Seed", "Adding sample data...")
        
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
      end
      
      def show_completion
        say_status_with_phase("900_PHASE_Complete", "Template application completed!")
        
        say "Rails 8 Simple Template applied successfully!", :green
        say "Next steps:", :blue
        say "  1. Start the server: bin/rails server"
        say "  2. Visit http://localhost:3000"
        say "  3. Customize your application"
      end
    end
  end
end