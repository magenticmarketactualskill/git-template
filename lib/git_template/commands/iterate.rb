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
require_relative '../models/result/iterate_command_result'
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
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "iterate",
                  error_message: iteration_strategy_result.reason
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Execute iteration based on strategy
              case iteration_strategy_result.strategy_type
              when :repo_iteration
                result = recreate_repo(analysis, options)
              when :create_templated_folder
                result = create_templated_folder(analysis, template_processor, options)
              when :template_iteration
                result = rerun_template(analysis, template_processor, options)
              else
                raise StatusCommandError.new("Cannot iterate: #{iteration_strategy_result.reason}")
              end
              
              # All results inherit from Models::Result::Base and handle their own formatting
              puts result.format_output(options[:format], options)
              
              result
            end
          end
          
          private
          
          define_method :create_templated_folder do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            begin
              # Create templated folder and copy configuration
              result = template_processor.create_templated_folder(folder_path, options)
              
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "iterate",
                data: {
                  folder_path: folder_path,
                  iteration_type: "create_templated_folder",
                  result: result
                }
              )
            rescue => e
              Models::Result::IterateCommandResult.new(
                success: false,
                operation: "iterate",
                error_message: "Templated folder creation failed: #{e.message}"
              )
            end
          end
          
          define_method :rerun_template do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            begin
              # Update template configuration only
              result = template_processor.update_template_configuration(folder_path, options)
              
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "iterate",
                data: {
                  folder_path: folder_path,
                  iteration_type: "template_iteration",
                  result: result
                }
              )
            rescue => e
              Models::Result::IterateCommandResult.new(
                success: false,
                operation: "iterate",
                error_message: "Template update failed: #{e.message}"
              )
            end
          end
          
          define_method :recreate_repo do |analysis, options|
            template_iteration_service = Services::TemplateIteration.new
            
            # Execute full iteration
            iteration_data = template_iteration_service.execute_repo_iteration(analysis, options)
            
            # Create result object
            Models::Result::IterationResult.new(iteration_data)
          end


        end
      end
    end
  end
end