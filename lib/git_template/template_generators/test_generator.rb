module GitTemplate
  module TemplateGenerators
    module TestGenerator
      def self.execute
        say "#~ 050_PHASE_Test"
        say "Setting up RSpec testing framework..."
        
        generate 'rspec:install'
      end
    end
  end
end