# Rails 8 + Juris.js Application Template
# This template creates a Rails 8 application with Juris.js frontend and ActiveDataFlow integration
#
# Usage:
#   rails new myapp -m template.rb
#   bin/rails app:template LOCATION=template.rb (for existing apps)

def source_paths
  [__dir__]
end

# Display welcome message
say "=" * 80
say "Rails 8 + Juris.js Application Template"
say "=" * 80
say ""
say "This template will set up a Rails 8 application with:"
say "  • Juris.js frontend framework"
say "  • Inertia.js for Rails integration"
say "  • TailwindCSS for styling"
say "  • ActiveDataFlow for data transformation"
say "  • RSpec and Cucumber for testing"
say "  • Pundit for authorization"
say "  • Admin interface with infrastructure/users/financial tabs"
say ""

# Ask user for configuration preferences
@use_redis = yes?("Use Redis? (no = use redis-emulator)")
@use_active_data_flow = yes?("Include ActiveDataFlow integration?")
@use_docker = yes?("Setup Docker/Kamal deployment?")
@generate_sample_models = yes?("Generate sample Product models?")
@setup_admin = yes?("Setup admin interface?")

say "\nStarting template application...\n", :green

# Phase 1: Platform Setup
say "\n" + "=" * 80
say "Phase 1: Platform Setup"
say "=" * 80 + "\n"

apply "modules/01_platform/ruby_version.rb"
apply "modules/01_platform/rails_config.rb"
apply "modules/01_platform/database.rb"

# Phase 2: Infrastructure
say "\n" + "=" * 80
say "Phase 2: Infrastructure Setup"
say "=" * 80 + "\n"

apply "modules/02_infrastructure/gems.rb"
apply "modules/02_infrastructure/redis.rb"
apply "modules/02_infrastructure/solid_stack.rb"
apply "modules/02_infrastructure/deployment.rb" if @use_docker

# Phase 3: Frontend
say "\n" + "=" * 80
say "Phase 3: Frontend Setup"
say "=" * 80 + "\n"

apply "modules/03_frontend/vite.rb"
apply "modules/03_frontend/tailwind.rb"
apply "modules/03_frontend/inertia.rb"
apply "modules/03_frontend/juris.rb"

# Phase 4: Testing
say "\n" + "=" * 80
say "Phase 4: Testing Setup"
say "=" * 80 + "\n"

apply "modules/04_testing/rspec.rb"
apply "modules/04_testing/cucumber.rb"

# Phase 5: Security
say "\n" + "=" * 80
say "Phase 5: Security Setup"
say "=" * 80 + "\n"

apply "modules/05_security/authorization.rb"
apply "modules/05_security/security_gems.rb"

# Phase 6: Data Flow
if @use_active_data_flow
  say "\n" + "=" * 80
  say "Phase 6: ActiveDataFlow Setup"
  say "=" * 80 + "\n"
  
  apply "modules/06_data_flow/active_data_flow.rb"
end

# Phase 7: Application Features
say "\n" + "=" * 80
say "Phase 7: Application Features"
say "=" * 80 + "\n"

apply "modules/07_application/models.rb" if @generate_sample_models
apply "modules/07_application/controllers.rb"
apply "modules/07_application/views.rb"
apply "modules/07_application/routes.rb"
apply "modules/07_application/admin.rb" if @setup_admin

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
