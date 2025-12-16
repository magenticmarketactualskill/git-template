module GitTemplate
  module TemplateGenerators
    module HomeFeatureGenerator
      def self.execute
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
      end
    end
  end
end