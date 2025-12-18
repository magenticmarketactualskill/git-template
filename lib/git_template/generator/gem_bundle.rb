require_relative 'base'

module GitTemplate
  module Generators
    class GemBundle < Base
      def self.execute
        raise "Must override - implement data_module method"
      end

      def self.install_gem_groups
        data = data_module
        
        if data.const_defined?(:DEVELOPMENT_TEST_GEMS)
          install_gem_group(
            [:development, :test], 
            data::DEVELOPMENT_TEST_GEMS, 
            data::DEVELOPMENT_TEST_GEMS_MESSAGE
          )
        end
        
        if data.const_defined?(:DEVELOPMENT_GEMS)
          install_gem_group(
            [:development], 
            data::DEVELOPMENT_GEMS, 
            data::DEVELOPMENT_GEMS_MESSAGE
          )
        end
      end

      private



      def self.install_gem_group(groups, gems, message)
        say message if message
        
        gem_group(*groups) do
          gems.each do |gem_name|
            gem gem_name unless File.read('Gemfile').include?(gem_name)
          end
        end
      end
    end
  end
end