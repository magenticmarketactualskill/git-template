# IterateCommand Concern
#
# This command handles template iteration with configuration preservation,
# template application and comparison functionality, integrating with
# TemplateProcessor service for the iterative template development process.

require_relative 'base'
require_relative 'submodule_protection'
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
          include SubmoduleProtection
          desc "iterate", "Handle template iteration with configuration preservation"
          add_common_options
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          option :path, type: :string, default: ".", desc: "Folder path to iterate (defaults to current directory)"
          
          define_method :iterate do
            execute_with_error_handling("iterate", options) do
              path = options[:path] || "."
              log_command_execution("iterate", [path], options)
              setup_environment(options)
              
              # Check if path is a submodule - if so, reject the operation
              protection_result = check_submodule_protection(path, "iterate")
              if protection_result
                puts protection_result.format_output(options[:format], options)
                return protection_result
              end
              
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
                result = iterate_create_templated_folder(analysis, template_processor, options)
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
          
          define_method :iterate_create_templated_folder do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            # Create templated folder and copy configuration
            template_processor.create_templated_folder(folder_path, options)
          end
          
          define_method :rerun_template do |analysis, template_processor, options|
            folder_path = analysis[:folder_analysis].path
            
            # Update template configuration only
            template_processor.update_template_configuration(folder_path, options)
          end
          
          define_method :recreate_repo do |analysis, options|
            template_iteration_service = Services::TemplateIteration.new
            
            # Execute full iteration
            iteration_data = template_iteration_service.execute_repo_iteration(analysis, options)
            
            # Create result object
            Models::Result::IterationResult.new(iteration_data)
          end

          public

        end
      end
    end
  end
end