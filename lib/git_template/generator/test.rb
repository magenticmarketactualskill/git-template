require_relative 'base'

module GitTemplate
  module Generators
    class Test < Base
      def self.execute
        execute_with_messages do |data, messages|
          say_next_message(messages, "Setting up testing framework...")
          say_next_message(messages)
          
          if data.respond_to?(:generators)
            run_generators(data.generators.to_a)
          end
        end
      end
    end
  end
end