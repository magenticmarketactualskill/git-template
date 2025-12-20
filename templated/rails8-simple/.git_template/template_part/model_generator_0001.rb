lib_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib')
puts "Adding to load path: #{lib_path}"
puts "Resolved path: #{File.expand_path(lib_path)}"
$LOAD_PATH.unshift(lib_path)


class ModelGenerator0001 < GitTemplate::Generators::Base
  include GitTemplate::Generators::Model
  
  
  repo_path 'app/models/application_record.rb'
  
  golden_text <<~RUBY
    class ApplicationRecord < ActiveRecord::Base
      primary_abstract_class
    end
  RUBY
end