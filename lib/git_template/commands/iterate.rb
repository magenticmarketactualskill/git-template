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
          option :detailed_comparison, type: :boolean, desc: "Generate detailed comparison report"
          option :format, type: :string, default: "detailed", desc: "Output format (detailed, summary, json)"
          
          define_method :iterate do |path = "."|
            execute_with_error_handling("iterate", options) do
              log_command_execution("iterate", [path], options)
              
              measure_execution_time do
                template_processor = Services::TemplateProcessor.new
                folder_analyzer = Services::FolderAnalyzer.new
                iteration_strategy_service = Services::IterationStrategy.new
                
                # Validate and analyze folder
                validated_path = validate_directory_path(path, must_exist: true)
                analysis = iteration_strategy_service.analyze_folder_for_iteration(validated_path, folder_analyzer)
                
                # Determine iteration strategy
                iteration_strategy_result = iteration_strategy_service.determine_iteration_strategy(analysis, options)
                
                # Check if iteration can proceed
                unless iteration_strategy_result.can_proceed
                  result = create_error_response("iterate", iteration_strategy_result.reason)
                  puts format_response_for_output(result, options)
                  return result
                end
                
                # Execute iteration based on strategy
                case iteration_strategy_result.strategy_type
                when :repo_iteration
                  template_iteration_service = Services::TemplateIteration.new
                  iteration_data = template_iteration_service.execute_repo_iteration(analysis, options)
                  iteration_result = Models::Result::IterationResult.new(iteration_data)
                  
                  success_response = create_success_response("iterate", {
                    folder_path: iteration_result.application_folder,
                    iteration_type: "repo_iteration",
                    result: iteration_result.summary
                  })
                  
                  puts format_response_for_output(success_response, options)
                  success_response
                when :create_templated_folder
                  execute_create_templated_folder(analysis, template_processor, options)
                when :template_iteration
                  execute_template_iteration(analysis, template_processor, options)
                else
                  raise StatusCommandError.new("Cannot iterate: #{iteration_strategy_result.reason}")
                end
              end
            end
          end
          
          private
          

          
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
          
          define_method :execute_template_iteration do |analysis, template_processor, options|
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
        end
      end
    end
  end
end