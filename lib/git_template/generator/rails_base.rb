require 'rails/generators'

module GitTemplate
  class TemplateGeneratorBase < Rails::Generators::Base
    include Rails::Generators::Actions
    
    # Common template generator functionality
    def self.source_root
      @source_root ||= File.expand_path("../../../templates", __FILE__)
    end
    
    protected
    
    def say_status_with_phase(phase, message, status = :green)
      say "#~ #{phase}", status
      say message, status
    end
    
    def gem_exists?(gem_name)
      File.read('Gemfile').include?(gem_name)
    rescue
      false
    end
    
    def add_gem_unless_exists(gem_name, *args)
      gem(gem_name, *args) unless gem_exists?(gem_name)
    end
    
    def add_gem_group_unless_exists(group, gems)
      gems.each do |gem_name, options|
        next if gem_exists?(gem_name)
        
        if options
          gem_group(group) { gem(gem_name, options) }
        else
          gem_group(group) { gem(gem_name) }
        end
      end
    end
  end
end