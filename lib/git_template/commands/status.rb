# StatusCommand Concern
#
# This concern provides comprehensive status analysis for application folders,
# including template configuration detection, git repository status, and
# development workflow recommendations.

require_relative 'base'
require_relative '../services/folder_analyzer'
require_relative '../services/status_reporter'
require_relative '../services/status_formatter'
require_relative '../services/iteration_strategy'
require_relative '../models/result/folder_analysis'

module GitTemplate
  module Command
    module Status
      def self.included(base)
        base.class_eval do
          
          desc "status [PATH]", "Check the status of application folders for template development"
          add_common_options
          
          define_method :status do |folder_path = "."|
            execute_with_error_handling("status", options) do
              log_command_execution("status", [folder_path], options)
              
              measure_execution_time do
                setup_environment(options)
                
                # Validate and analyze folder
                validated_path = validate_directory_path(folder_path, must_exist: false)
                folder_analysis_data = analyze_folder_status(validated_path)

                # Generate and output report
                result = generate_status_report(folder_analysis_data, options)
                
                # Output based on format
                case options[:format]
                when "json"
                  puts JSON.pretty_generate(result)
                when "summary"
                  status_formatter = Services::StatusFormatter.new
                  puts status_formatter.format_summary_status(result)
                else
                  puts result[:data][:report]
                end
                
                result
              end
            end
          end
          
          private
          
          define_method :analyze_folder_status do |folder_path|
            folder_analyzer = Services::FolderAnalyzer.new
            folder_analyzer.analyze_template_development_status(folder_path)
          end
          
          define_method :generate_status_report do |analysis_data, options|
            status_reporter = Services::StatusReporter.new
            
            # Convert analysis data to StatusResult
            status_result = status_reporter.send(:convert_to_status_result, analysis_data)
            
            # Use the base class format_output method
            status_result.format_output(options[:format], options)
          end
          
          define_method :extract_status_summary do |analysis_data|
            # This method is now deprecated in favor of StatusResult.summary
            # but kept for backward compatibility
            folder_analysis = analysis_data[:folder_analysis]
            development_status = analysis_data[:development_status]
            
            {
              folder: folder_analysis[:path],
              status: development_status,
              exists: folder_analysis[:exists],
              git_repository: folder_analysis[:is_git_repository],
              template_configuration: folder_analysis[:has_template_configuration],
              templated_folder: folder_analysis[:templated_folder_exists],
              ready_for_iteration: development_status == :ready_for_template_iteration
            }
          end
          

        end
      end
    end
  end
end
