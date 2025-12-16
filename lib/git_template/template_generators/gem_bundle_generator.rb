module GitTemplate
  module TemplateGenerators
    module GemBundleGenerator
      def self.execute
        say "#~ 030_PHASE_GemBundle_Development_Test"
        say "Adding development and test gems..."
        
        gem_group :development, :test do
          gem 'rspec-rails' unless File.read('Gemfile').include?('rspec-rails')
          gem 'factory_bot_rails'
          gem 'faker'
        end
        
        say "#~ 030_PHASE_GemBundle_Development"
        say "Adding development gems..."
        
        gem_group :development do
          gem 'annotate' unless File.read('Gemfile').include?('annotate')
          gem 'better_errors'
          gem 'binding_of_caller'
        end
      end
    end
  end
end