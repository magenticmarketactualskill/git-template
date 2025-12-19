require_relative 'base'

module GitTemplate
  module Generators
    class PostFeature < Base
      def self.data_module
        p "#{self} Must override data module"
      end
      def self.execute
        execute_with_messages do |data, messages|
          # Model generation
          say_next_message(messages, "Creating model...")
          say_next_message(messages)
          
          if data.const_defined?(:MODEL_CONFIG)
            config = data::MODEL_CONFIG
            generate :model, config[:name], *config[:attributes]
          end
          
          # Database operations
          say_next_message(messages, "Running database operations...")
          say_next_message(messages)
          
          if data.respond_to?(:commands)
            run_rails_commands(data.commands.to_a)
          end
          
          # Seed data
          if data.const_defined?(:SEED_DATA)
            say_next_message(messages, "Adding seed data...")
            say_next_message(messages)
            
            append_to_file 'db/seeds.rb', data::SEED_DATA
            
            # Run seed command if available
            if data.respond_to?(:commands)
              commands = data.commands.to_a
              if commands.include?('db:seed')
                rails_command 'db:seed'
              end
            end
          end
        end
      end
    end
  end
end