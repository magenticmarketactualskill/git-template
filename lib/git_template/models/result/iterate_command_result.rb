# IterateCommandResult Model
#
# This class represents the result of an iterate command execution,
# providing consistent formatting and output handling.

require_relative 'base'

module GitTemplate
  module Models
    module Result
      class IterateCommandResult < Base
        attr_reader :operation, :success, :error_message, :error_type, :data

        def initialize(success:, operation:, data: {}, error_message: nil, error_type: nil)
          super()
          @success = success
          @operation = operation
          @data = data || {}
          @error_message = error_message
          @error_type = error_type
        end

        def successful?
          @success
        end

        def failed?
          !@success
        end

        def summary
          if successful?
            "✅ #{@operation} completed successfully"
          else
            "❌ #{@operation} failed: #{@error_message}"
          end
        end

        def format_as_json(options = {})
          require 'json'
          
          response_data = {
            success: @success,
            operation: @operation,
            timestamp: @timestamp.iso8601
          }
          
          if successful?
            response_data.merge!(@data)
          else
            response_data[:error] = @error_message
            response_data[:error_type] = @error_type if @error_type
          end
          
          JSON.pretty_generate(response_data)
        end

        def format_as_summary(options = {})
          summary
        end

        def format_as_detailed(options = {})
          output = []
          
          if successful?
            output << "✅ Operation: #{@operation}"
            output << "   Status: Success"
            output << "   Timestamp: #{@timestamp.iso8601}"
            
            # Add operation-specific details
            @data.each do |key, value|
              next if [:success, :operation, :timestamp].include?(key)
              output << "   #{key.to_s.capitalize.gsub('_', ' ')}: #{value}"
            end
          else
            output << "❌ Operation: #{@operation}"
            output << "   Status: Failed"
            output << "   Error: #{@error_message}"
            output << "   Error Type: #{@error_type}" if @error_type
            output << "   Timestamp: #{@timestamp.iso8601}"
          end
          
          output.join("\n")
        end

        def extract_folder_path
          @data[:folder_path] || @data[:application_folder] || "Unknown path"
        end

        # Convert legacy hash responses to IterateCommandResult
        def self.from_hash(hash)
          if hash[:success]
            new(
              success: true,
              operation: hash[:operation] || "iterate",
              data: hash.reject { |k, v| [:success, :operation, :timestamp].include?(k) }
            )
          else
            new(
              success: false,
              operation: hash[:operation] || "iterate",
              error_message: hash[:error],
              error_type: hash[:error_type]
            )
          end
        end
      end
    end
  end
end