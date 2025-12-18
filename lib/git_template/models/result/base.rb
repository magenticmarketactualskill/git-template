# Base Result Model
#
# This class provides common functionality for all result models
# in the GitTemplate system.

require_relative '../../status_command_errors'

module GitTemplate
  module Models
    module Result
      class Base
        include StatusCommandErrors

        attr_reader :timestamp

        def initialize
          @timestamp = Time.now
        end

        # Common interface methods that subclasses should implement
        def summary
          raise NotImplementedError, "Subclasses must implement #summary"
        end

        # Format output based on the specified format type
        def format_output(format_type, options = {})
          case format_type.to_s.downcase
          when "json"
            format_as_json(options)
          when "summary"
            format_as_summary(options)
          when "detailed", "detail"
            format_as_detailed(options)
          else
            format_as_detailed(options)
          end
        end

        # Create a success response structure
        def create_success_response(command, data = {})
          {
            success: true,
            command: command,
            timestamp: @timestamp,
            data: data
          }
        end

        # Format as JSON output
        def format_as_json(options = {})
          require 'json'
          
          response_data = {
            analysis: respond_to?(:to_hash) ? to_hash : summary,
            folder_path: extract_folder_path
          }
          
          create_success_response("status", response_data)
        end

        # Format as summary output
        def format_as_summary(options = {})
          response_data = {
            summary: summary,
            folder_path: extract_folder_path
          }
          
          create_success_response("status", response_data)
        end

        # Format as detailed output (default)
        def format_as_detailed(options = {})
          response_data = {
            report: generate_detailed_report(options),
            analysis: respond_to?(:to_hash) ? to_hash : summary,
            folder_path: extract_folder_path
          }
          
          create_success_response("status", response_data)
        end

        # Generate detailed report - subclasses should override if needed
        def generate_detailed_report(options = {})
          if respond_to?(:to_s)
            to_s
          else
            "Detailed report not available for #{self.class.name}"
          end
        end

        # Extract folder path - subclasses should override if needed
        def extract_folder_path
          if respond_to?(:folder_analysis) && folder_analysis.respond_to?(:path)
            folder_analysis.path
          elsif respond_to?(:path)
            path
          else
            "Unknown path"
          end
        end

        protected

        # Common utility methods for result classes
        def expand_path(path)
          File.expand_path(path)
        end

        def current_time
          Time.now
        end
      end
    end
  end
end