module GitTemplate
  module Generators
    class Base
      def self.execute
        raise "Must override"
      end

      protected

      def self.data_module
        raise "Must override - return the data module"
      end

      def self.execute_with_messages(&block)
        data = data_module
        messages = data.respond_to?(:messages) ? data.messages : nil
        
        if messages
          yield(data, messages)
        else
          yield(data, nil)
        end
      end

      def self.run_generators(generators)
        generators.each do |generator_config|
          if generator_config.is_a?(Array)
            generate generator_config.first, *generator_config[1..-1]
          else
            generate generator_config
          end
        end
      end

      def self.run_rails_commands(commands)
        commands.each do |command|
          rails_command command
        end
      end

      def self.say_next_message(messages, fallback_message = nil)
        if messages
          say messages.next
        elsif fallback_message
          say fallback_message
        end
      end

      def self.apply_file_operations(operations)
        operations.each do |operation|
          case operation[:type]
          when :gsub_file
            gsub_file operation[:file], operation[:from], operation[:to]
          when :append_to_file
            append_to_file operation[:file], operation[:content]
          when :create_file
            create_file operation[:file], operation[:content]
          end
        end
      end
    end
  end
end
