# IterateCommand Concern
#
# This command handles template iteration with configuration preservation,
# template application and comparison functionality, integrating with
# TemplateProcessor service for the iterative template development process.

require_relative 'base'
require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../services/iteration_strategy'
require_relative '../services/template_iteration'
require_relative '../models/result/iteration_result'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module Iterate
      def self.included(base)
        base.class_eval do
          desc "iterate [PATH]", "Handle template iteration with configuration preservation"
          add_common_options
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          
          define_method :iterate do |path = "."|
            execute_with_error_handling("iterate", options) do
              log_command_execution("iterate", [path], options)
              
              measure_execution_time do
                setup_environment(options)
                template_processor = Services::TemplateProcessor.new
                folder_analyzer = Services::FolderAnalyzer.new
                iteration_strategy_service = Services::IterationStrategy.new
                
                # Validate and analyze folder
                validated_path = validate_directory_path(path, must_exist: true)
                analysis = iteration_strategy_service.analyze_folder_for_iteration(validated_path, folder_analyzer)
                
                # Determine iteration strategy
                iteration_strategy_result = iteration_strategy_service.determine_iteration_strategy(analysis, options)
                
                # Check if iteration can proceed
                unless iteration_strategy_result.can_proceed || options[:force]
                  result = create_error_response("iterate", iteration_strategy_result.reason)
                  puts format_response_for_output(result, options)
                  return result
                end
                
                # Execute iteration based on strategy
                case iteration_strategy_result.strategy_type
                when :repo_iteration
                  result = execute_repo_iteration(analysis, options)
                when :create_templated_folder
                  result = execute_create_templated_folder(analysis, template_processor, options)
                when :template_iteration
                  result = execute_template_iteration_update(analysis, template_processor, options)
                else
                  raise StatusCommandError.new("Cannot iterate: #{iteration_strategy_result.reason}")
                end
                
                # Output based on format
                case options[:format]
                when "json"
                  puts JSON.pretty_generate(result.is_a?(Models::Result::IterationResult) ? result.format_output("json", options) : result)
                when "summary"
                  if result.is_a?(Models::Result::IterationResult)
                    puts format_iteration_summary(result)
                  else
                    puts format_response_for_output(result, options)
                  end
                else
                  if result.is_a?(Models::Result::IterationResult)
                    formatted_result = result.format_output("detailed", options)
                    puts formatted_result[:data][:report]
                  else
                    puts format_response_for_output(result, options)
                  end
                end
                
                result
              end
            end
          end
          
          private
          
          define_method :execute_repo_iteration do |analysis, options|
            template_iteration_service = Services::TemplateIteration.new
            
            # Execute full iteration
            iteration_data = template_iteration_service.execute_repo_iteration(analysis, options)
            
            # Create result object
            Models::Result::IterationResult.new(iteration_data)
          end
          
          define_method :execute_create_templated_folder do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            begin
              # Create templated folder and copy configuration
              result = template_processor.create_templated_folder(folder_path, options)
              
              success_response = create_success_response("iterate", {
                folder_path: folder_path,
                iteration_type: "create_templated_folder",
                result: result
              })
              
              puts format_response_for_output(success_response, options)
              success_response
            rescue => e
              error_response = create_error_response("iterate", "Templated folder creation failed: #{e.message}")
              puts format_response_for_output(error_response, options)
              error_response
            end
          end
          
          define_method :execute_template_iteration_update do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            begin
              # Update template configuration only
              result = template_processor.update_template_configuration(folder_path, options)
              
              success_response = create_success_response("iterate", {
                folder_path: folder_path,
                iteration_type: "template_iteration",
                result: result
              })
              
              puts format_response_for_output(success_response, options)
              success_response
            rescue => e
              error_response = create_error_response("iterate", "Template update failed: #{e.message}")
              puts format_response_for_output(error_response, options)
              error_response
            end
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