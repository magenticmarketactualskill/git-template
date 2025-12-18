# StatusCommand Concern
#
# This concern provides comprehensive status analysis for application folders,
# including template configuration detection, git repository status, and
# development workflow recommendations.

require_relative 'base'
require_relative '../services/folder_analyzer'
require_relative '../services/status_reporter'

module GitTemplate
  module Command
    module Status
      def self.included(base)
        base.class_eval do
          
          desc "status [PATH]", "Check the status of application folders for template development"
          option :format, type: :string, default: "detailed", desc: "Output format: detailed, summary, json"
          option :verbose, type: :boolean, default: false, desc: "Show verbose output"
          option :debug, type: :boolean, default: false, desc: "Show debug information"
          
          define_method :status do |folder_path = "."|
            execute_with_error_handling("status", options) do
              log_command_execution("status", [folder_path], options)
              
              measure_execution_time do
                setup_environment(options)
                
                # Validate and analyze folder
                validated_path = validate_directory_path(folder_path, must_exist: false)
                folder_analysis_data = analyze_folder_status(validated_path)
                
                iteration_analysis = analyze_folder_for_iteration(validated_path, folder_analyzer)
                iteration_strategy = determine_iteration_strategy(analysis, options)

                # Generate and output report
                result = generate_status_report(analysis_data, options)
                
                # Output based on format
                case options[:format]
                when "json"
                  puts JSON.pretty_generate(result)
                when "summary"
                  puts format_summary_status(result)
                else
                  puts result[:report]
                end
                
                result
              end
            end
          end
          
          private
          
          define_method :setup_environment do |opts|
            ENV['VERBOSE'] = '1' if opts[:verbose]
            ENV['DEBUG'] = '1' if opts[:debug]
          end
          
          define_method :analyze_folder_status do |folder_path|
            folder_analyzer = Services::FolderAnalyzer.new
            folder_analyzer.analyze_template_development_status(folder_path)
          end
          
          define_method :generate_status_report do |analysis_data, options|
            status_reporter = Services::StatusReporter.new
            
            case options[:format]
            when "json"
              create_success_response("status", {
                analysis: analysis_data,
                folder_path: analysis_data.dig(:folder_analysis, :path)
              })
            when "summary"
              create_success_response("status", {
                summary: extract_status_summary(analysis_data),
                folder_path: analysis_data.dig(:folder_analysis, :path)
              })
            else
              report = status_reporter.generate_report(analysis_data)
              create_success_response("status", {
                report: report,
                analysis: analysis_data,
                folder_path: analysis_data.dig(:folder_analysis, :path)
              })
            end
          end
          
          define_method :extract_status_summary do |analysis_data|
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
          
          define_method :format_summary_status do |result|
            summary = result[:summary]
            output = []
            
            output << "Folder: #{summary[:folder]}"
            output << "Status: #{summary[:status]}"
            output << "Exists: #{summary[:exists] ? '✅' : '❌'}"
            output << "Git repository: #{summary[:git_repository] ? '✅' : '❌'}"
            output << "Template configuration: #{summary[:template_configuration] ? '✅' : '❌'}"
            output << "Templated folder: #{summary[:templated_folder] ? '✅' : '❌'}"
            output << "Ready for iteration: #{summary[:ready_for_iteration] ? '✅' : '❌'}"
            
            output.join("\n")
          end
        end
      end
    end
  end
end
