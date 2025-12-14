# Rails 8 + Juris.js Application Template (TemplateLifecycle)
# This template creates a Rails 8 application with Juris.js frontend and ActiveDataFlow integration
# Now using the TemplateLifecycle system for organized, extensible template management
#
# Usage:
#   rails new myapp -m template.rb
#   bin/rails app:template LOCATION=template.rb (for existing apps)

def source_paths
  [__dir__]
end

# Load the TemplateLifecycle system
require_relative 'lib/template_lifecycle'

# Initialize and execute the TemplateLifecycle
lifecycle = TemplateLifecycle.new(self)

# Add conditional module execution based on configuration
lifecycle.phases.each do |phase|
  case phase.folder_name
  when 'infrastructure'
    # Add condition for deployment module
    deployment_module = phase.modules.find { |m| m[:path].include?('deployment') }
    if deployment_module
      deployment_module[:conditions] = { use_docker: true }
    end
  when 'data_flow'
    # Add condition for ActiveDataFlow modules
    phase.modules.each do |module_info|
      module_info[:conditions] = { use_active_data_flow: true }
    end
  when 'application'
    # Add condition for models module
    models_module = phase.modules.find { |m| m[:path].include?('models') }
    if models_module
      models_module[:conditions] = { generate_sample_models: true }
    end
    
    # Add condition for admin module
    admin_module = phase.modules.find { |m| m[:path].include?('admin') }
    if admin_module
      admin_module[:conditions] = { setup_admin: true }
    end
  end
end

# Execute the template lifecycle
execution_summary = lifecycle.execute

# After bundle tasks
after_bundle do
  say "\n" + "=" * 80
  say "Post-Installation Tasks"
  say "=" * 80 + "\n"
  
  # Install JavaScript dependencies
  say "Installing JavaScript dependencies...", :green
  run "npm install"
  
  # Build frontend assets
  say "Building frontend assets...", :green
  run "npm run build"
  
  # Setup database
  if @generate_sample_models
    say "Setting up database...", :green
    rails_command "db:create"
    rails_command "db:migrate"
    
    if yes?("Load seed data?")
      rails_command "db:seed"
    end
  end
  
  # Initialize git repository
  if yes?("Initialize git repository?")
    git :init
    git add: "."
    git commit: "-m 'Initial commit: Rails 8 + Juris.js application'"
  end
  
  # Display completion message
  say "\n" + "=" * 80
  say "Installation Complete!"
  say "=" * 80 + "\n"
  
  say "Your Rails 8 + Juris.js application is ready!", :green
  say ""
  say "Next steps:"
  say "  1. Start the development server:"
  say "     bin/dev"
  say ""
  say "  2. Visit http://localhost:3000"
  say ""
  
  if @use_active_data_flow && @generate_sample_models
    say "  3. Trigger DataFlow processing:"
    say "     curl -X POST http://localhost:3000/active_data_flow/data_flows/heartbeat"
    say ""
    say "  4. View DataFlows dashboard:"
    say "     http://localhost:3000/active_data_flow/data_flows"
    say ""
  end
  
  say "Happy coding! 🚀", :green
  say ""
end
