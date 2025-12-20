lib_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib')
puts "Adding to load path: #{lib_path}"
puts "Resolved path: #{File.expand_path(lib_path)}"
$LOAD_PATH.unshift(lib_path)


class ControllerGenerator0001 < GitTemplate::Generators::Base
  include GitTemplate::Generators::Controller
  
  
  repo_path 'app/controllers/application_controller.rb'
  
  golden_text <<~RUBY
    class ApplicationController < ActionController::Base
      # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
      allow_browser versions: :modern
    
      # Changes to the importmap will invalidate the etag for HTML responses
      stale_when_importmap_changes
    end
  RUBY
end