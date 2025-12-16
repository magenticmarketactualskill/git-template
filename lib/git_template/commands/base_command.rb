# BaseCommand Class
#
# This base class provides common functionality for all command classes,
# including consistent error handling, logging, and command execution flow.

require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class BaseCommand
      include StatusCommandErrors

      def initialize
        @logger = setup_logger
      end

      protected

      def setup_logger
        # Simple logger setup - could be enhanced with proper logging library
        logger = Object.new
        
        def logger.info(message)
          puts "[INFO] #{Time.now.strftime('%H:%M:%S')} #{message}" if ENV['VERBOSE'] || ENV['DEBUG']
        end
        
        def logger.error(message)
          puts "[ERROR] #{Time.now.strftime('%H:%M:%S')} #{message}"
        end
        
        def logger.debug(message)
          puts "[DEBUG] #{Time.now.strftime('%H:%M:%S')} #{message}" if ENV['DEBUG']
        end
        
        def logger.warn(message)
          puts "[WARN] #{Time.now.strftime('%H:%M:%S')} #{message}"
        end
        
        logger
      end

      def execute_with_error_handling(operation_name, options = {})
        @logger.info("Starting #{operation_name}")
        
        begin
          result = yield
          
          @logger.info("Completed #{operation_name} successfully")
          result
          
        rescue StatusCommandError => e
          @logger.error("#{operation_name} failed: #{e.message}")
          handle_known_error(e, operation_name, options)
        rescue => e
          @logger.error("Unexpected error in #{operation_name}: #{e.message}")
          @logger.debug("Backtrace: #{e.backtrace.join("\n")}") if ENV['DEBUG']
          handle_unexpected_error(e, operation_name, options)
        end
      end

      def validate_required_options(options, required_keys)
        missing_keys = required_keys.select { |key| options[key].nil? || options[key].to_s.strip.empty? }
        
        unless missing_keys.empty?
          raise StatusCommandError.new("Missing required options: #{missing_keys.join(', ')}")
        end
      end

      def validate_file_path(path, must_exist: true)
        if path.nil? || path.strip.empty?
          raise InvalidPathError.new("Path cannot be empty")
        end
        
        expanded_path = File.expand_path(path.strip)
        
        if must_exist && !File.exist?(expanded_path)
          raise InvalidPathError.new("Path does not exist: #{expanded_path}")
        end
        
        expanded_path
      end

      def validate_directory_path(path, must_exist: true)
        expanded_path = validate_file_path(path, must_exist: false)
        
        if must_exist && !File.directory?(expanded_path)
          raise InvalidPathError.new("Path is not a directory: #{expanded_path}")
        elsif File.exist?(expanded_path) && !File.directory?(expanded_path)
          raise InvalidPathError.new("Path exists but is not a directory: #{expanded_path}")
        end
        
        expanded_path
      end

      def create_success_response(operation, data = {})
        {
          success: true,
          operation: operation,
          timestamp: Time.now.iso8601
        }.merge(data)
      end

      def create_error_response(operation, error_message, error_type = nil)
        {
          success: false,
          operation: operation,
          error: error_message,
          error_type: error_type,
          timestamp: Time.now.iso8601
        }
      end

      def format_response_for_output(result, options = {})
        case options[:format]
        when 'json', :json
          require 'json'
          JSON.pretty_generate(result)
        when 'summary', :summary
          format_summary_output(result)
        else
          format_detailed_output(result)
        end
      end

      def format_summary_output(result)
        if result[:success]
          "✅ #{result[:operation]} completed successfully"
        else
          "❌ #{result[:operation]} failed: #{result[:error]}"
        end
      end

      def format_detailed_output(result)
        output = []
        
        if result[:success]
          output << "✅ Operation: #{result[:operation]}"
          output << "   Status: Success"
          output << "   Timestamp: #{result[:timestamp]}"
          
          # Add operation-specific details
          result.each do |key, value|
            next if [:success, :operation, :timestamp].include?(key)
            output << "   #{key.to_s.capitalize.gsub('_', ' ')}: #{value}"
          end
        else
          output << "❌ Operation: #{result[:operation]}"
          output << "   Status: Failed"
          output << "   Error: #{result[:error]}"
          output << "   Error Type: #{result[:error_type]}" if result[:error_type]
          output << "   Timestamp: #{result[:timestamp]}"
        end
        
        output.join("\n")
      end

      def handle_known_error(error, operation_name, options)
        create_error_response(operation_name, error.message, error.class.name)
      end

      def handle_unexpected_error(error, operation_name, options)
        error_message = "Unexpected error: #{error.message}"
        
        if options[:debug] || ENV['DEBUG']
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        create_error_response(operation_name, error_message, error.class.name)
      end

      def log_command_execution(command_name, args, options)
        @logger.info("Executing command: #{command_name}")
        @logger.debug("Arguments: #{args.inspect}")
        @logger.debug("Options: #{options.inspect}")
      end

      def measure_execution_time
        start_time = Time.now
        result = yield
        end_time = Time.now
        
        execution_time = end_time - start_time
        @logger.info("Execution completed in #{execution_time.round(2)} seconds")
        
        if result.is_a?(Hash)
          result[:execution_time] = execution_time
        end
        
        result
      end

      def ensure_directory_exists(path)
        FileUtils.mkdir_p(path) unless File.directory?(path)
      end

      def safe_file_operation
        begin
          yield
        rescue Errno::EACCES => e
          raise StatusCommandError.new("Permission denied: #{e.message}")
        rescue Errno::ENOENT => e
          raise StatusCommandError.new("File or directory not found: #{e.message}")
        rescue Errno::ENOSPC => e
          raise StatusCommandError.new("No space left on device: #{e.message}")
        rescue => e
          raise StatusCommandError.new("File operation failed: #{e.message}")
        end
      end
    end
  end
end