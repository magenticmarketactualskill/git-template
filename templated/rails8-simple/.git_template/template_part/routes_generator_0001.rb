lib_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib')
puts "Adding to load path: #{lib_path}"
puts "Resolved path: #{File.expand_path(lib_path)}"
$LOAD_PATH.unshift(lib_path)


class RoutesGenerator0001 < GitTemplate::Generators::Base
  include GitTemplate::Generators::Routes
  
  
  repo_path 'config/routes.rb'
  
  @routes = [
    "get \"up\" => \"rails/health#show\", as: :rails_health_check",
  ]
end