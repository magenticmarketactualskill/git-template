# Setup Pundit for authorization (Rails best practice)
say "Setting up authorization with Pundit...", :green

# Add Pundit gem
gem "pundit", comment: "Minimal authorization through OO design and pure Ruby classes"

# Pundit will be installed and configured in after_bundle
after_bundle do
  # Generate Pundit configuration
  generate "pundit:install"
  
  # Include Pundit in ApplicationController
  inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
    <<-RUBY
  include Pundit::Authorization
  
  # Rescue from Pundit::NotAuthorizedError
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  private
  
  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
    RUBY
  end
  
  say "✓ Pundit configured", :green
end

say "✓ Pundit gem added (will be configured after bundle)", :green
