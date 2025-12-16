module GitTemplate
  module TemplateGenerators
    module ViewGenerator
      def self.execute
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
      end
    end
  end
end