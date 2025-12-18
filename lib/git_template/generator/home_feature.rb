require_relative 'base'

module GitTemplate
  module Generators
    class HomeFeature < Base
      def self.execute
        execute_with_messages do |data, messages|
          # Controller generation
          say_next_message(messages, "Creating controller...")
          say_next_message(messages)
          
          if data.const_defined?(:CONTROLLER_CONFIG)
            config = data::CONTROLLER_CONFIG
            generate :controller, config[:name], *config[:actions]
          end
          
          # Route setup
          say_next_message(messages, "Setting up routes...")
          say_next_message(messages)
          
          if data.const_defined?(:ROUTE_CONFIG)
            route data::ROUTE_CONFIG
          end
          
          # View creation
          say_next_message(messages, "Creating views...")
          say_next_message(messages)
          
          if data.const_defined?(:VIEW_CONTENT)
            create_file 'app/views/welcome/index.html.erb', data::VIEW_CONTENT
          end
        end
      end
    end
  end
end