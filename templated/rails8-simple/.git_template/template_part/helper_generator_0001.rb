lib_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib')
puts "Adding to load path: #{lib_path}"
puts "Resolved path: #{File.expand_path(lib_path)}"
$LOAD_PATH.unshift(lib_path)


class HelperGenerator0001 < GitTemplate::Generators::Base
  include GitTemplate::Generators::Helper
  
  
  repo_path 'app/helpers/application_helper.rb'
  
  golden_text <<~RUBY
    module ApplicationHelper
    end
  RUBY
end