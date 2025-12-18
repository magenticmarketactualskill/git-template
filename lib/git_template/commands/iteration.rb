# IterationCommand Concern
#
# This command handles full template iteration processes, including
# template application, comparison, and cleanup phase updates.

require_relative 'base'
require_relative '../services/folder_analyzer'
require_relative '../services/iteration_strategy'
require_relative '../services/template_iteration'
require_relative '../models/result/iteration_result'

module GitTemplate
  module Command
    module Iteration
      def self.included(base)
        base.class_eval do
          
          desc "iteration [PATH]", "Execute full template iteration process"
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          option :format, type: :string, default: "detailed", desc: "Output format: detailed, summary, json"
          option :verbose, type: :boolean, default: false, desc: "Show verbose output"
          option :debug, type: :boolean, default: false, desc: "Show debug information"
          option :force, type: :boolean, default: false, desc: "Force iteration even if prerequisites not fully met"
          
          define_method :iteration do |folder_path = "."|
            execute_with_error_handling("iteration", options) do
              log_command_execution("iteration", [folder_path], options)
              
              measure_execution_time do
                setup_environment(options)
                
                # Validate and analyze folder
                validated_path = validate_directory_path(folder_path, must_exist: true)
                
                # Analyze iteration readiness
                result = execute_template_iteration(validated_path, options)
                
                # Output based on format
                formatted_result = result.format_output(options[:format], options)
                
                case options[:format]
                when "json"
                  puts JSON.pretty_generate(formatted_result)
                when "summary"
                  puts format_iteration_summary(result)
                else
                  puts formatted_result[:data][:report]
                end
                
                formatted_result
              end
            end
          end
          
          private
          
          define_method :setup_environment do |opts|
            ENV['VERBOSE'] = '1' if opts[:verbose]
            ENV['DEBUG'] = '1' if opts[:debug]
          end
          
          define_method :execute_template_iteration do |folder_path, options|
            folder_analyzer = Services::FolderAnalyzer.new
            iteration_strategy_service = Services::IterationStrategy.new
            template_iteration_service = Services::TemplateIteration.new
            
            # Analyze folder for iteration
            analysis = iteration_strategy_service.analyze_folder_for_iteration(folder_path, folder_analyzer)
            
            # Determine if iteration can proceed
            strategy_result = iteration_strategy_service.determine_iteration_strategy(analysis, options)
            
            unless strategy_result.ready_for_iteration? || options[:force]
              raise StatusCommandError.new("Cannot execute iteration: #{strategy_result.reason}. Use --force to override.")
            end
            
            # Execute full iteration
            iteration_data = template_iteration_service.execute_repo_iteration(analysis, options)
            
            # Create result object
            Models::Result::IterationResult.new(iteration_data)
          end
          
          define_method :format_iteration_summary do |iteration_result|
            output = []
            
            output << "Template Iteration Summary"
            output << "=" * 40
            output << "Folder: #{File.basename(iteration_result.application_folder)}"
            output << "Status: #{iteration_result.successful? ? 'Success ✓' : 'Failed ✗'}"
            output << "Template Applied: #{iteration_result.template_applied ? 'Yes ✓' : 'No ✗'}"
            output << "Differences Found: #{iteration_result.differences_count}"
            output << "Cleanup Updated: #{iteration_result.cleanup_updated ? 'Yes' : 'No'}"
            
            if iteration_result.successful?
              if iteration_result.has_differences?
                output << ""
                output << "Next Steps:"
                output << "  1. Review differences with: git-template diff-result #{iteration_result.application_folder}"
                output << "  2. Refine template and iterate again"
              else
                output << ""
                output << "✅ Template iteration completed successfully!"
                output << "   No differences found - template is complete."
              end
            else
              output << ""
              output << "❌ Iteration failed. Check error messages and template configuration."
            end
            
            output.join("\n")
          end
        end
      end
    end
  end
end