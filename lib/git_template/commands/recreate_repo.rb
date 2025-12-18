# RecreateRepoCommand Concern
#
# This command performs a full repository iteration, recreating the templated folder
# from scratch and comparing it with the source application folder.

require_relative 'base'
require_relative '../services/template_iteration'
require_relative '../services/folder_analyzer'
require_relative '../services/iteration_strategy'
require_relative '../models/result/iteration_result'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module RecreateRepo
      def self.included(base)
        base.class_eval do
          desc "recreate-repo [PATH]", "Recreate repo creates a submodule with a git clone of the repo, creates a templated folder, and recreates the repo using the .git-template folder. It then does a comparison of the generated content with the original"
          add_common_options
          option :clean_before, type: :boolean, default: true, desc: "Clean templated folder before recreation"
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          
          define_method :recreate_repo do |path = "."|
            execute_with_error_handling("recreate_repo", options) do
              log_command_execution("recreate_repo", [path], options)
              setup_environment(options)
              
              # Determine if recreation can proceed
              if can_recreate_repo?.success
                
                # Execute repository recreation
                result = recreate_repo(analysis, template_iteration_service, options)
                
                # Format and display output
                puts result.format_output(options[:format], options)
              
              result
            end
          end
          
          private
          
          define_method :can_recreate_repo? do |iteration_strategy_result, options|
            
            iteration_strategy_service = Services::IterationStrategy.new
            iteration_strategy_result = iteration_strategy_service.determine_iteration_strategy(analysis, options)
            unless can_recreate_repo?(iteration_strategy_result, options)
              result = Models::Result::IterateCommandResult.new(
                success: false,
                operation: "recreate_repo",
                error_message: iteration_strategy_result.reason
              )
              puts result.format_output(options[:format], options)
              return result
            end

            # Allow recreation if it's ready for iteration or if force is enabled
            iteration_strategy_result.recreate_repo_can_proceed || 
            iteration_strategy_result.strategy_type == :recreate_repo ||
            options[:force]
          end
          
          define_method :recreate_repo do |analysis, template_iteration_service, options|
            begin
              #Recreate Repo
                # creates a submodule with a git clone of the repo
                # creates a templated folder
                # recreates the repo using the .git-template folder
                # does a comparison of the generated content with the original

            rescue => e
              # Return error result object
              Models::Result::IterateCommandResult.new(
                success: false,
                operation: "recreate_repo",
                error_message: e.message,
                error_type: e.class.name
              )
            end
          end
        end
      end
    end
  end
end