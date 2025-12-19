# UpdateRepoTemplateCommand Concern
#
# This command is specifically designed to update templates in submodule repositories.
# It's the only command that should write to submodule folders.

require_relative 'base'
require_relative 'submodule_protection'
require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module UpdateRepoTemplate
      def self.included(base)
        base.class_eval do
          include SubmoduleProtection
          desc "update-repo-template", "Update template in a submodule repository (only command allowed to write to submodules)"
          add_common_options
          option :path, type: :string, desc: "Submodule path (must be a git submodule)", required: true
          option :update_content, type: :boolean, default: true, desc: "Update template content based on current state"
          
          define_method :update_repo_template do
            execute_with_error_handling("update_repo_template", options) do
              path = options[:path]
              log_command_execution("update_repo_template", [path], options)
              setup_environment(options)
              
              # Validate that the path is a submodule
              unless is_submodule?(path)
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "update_repo_template",
                  error_message: "Path '#{path}' is not a git submodule. This command only works on submodules."
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              template_processor = Services::TemplateProcessor.new
              folder_analyzer = Services::FolderAnalyzer.new
              
              # Validate submodule folder
              validated_path = validate_directory_path(path, must_exist: true)
              
              # Analyze folder to ensure it has template configuration
              analysis = folder_analyzer.analyze_template_development_status(validated_path)
              folder_analysis = analysis[:folder_analysis]
              
              # Check if folder has template configuration
              unless folder_analysis[:has_template_configuration]
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "update_repo_template",
                  error_message: "No template configuration found at #{validated_path}. The submodule must have a .git_template folder."
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Apply template to regenerate application files in the submodule
              template_path = File.join(validated_path, '.git_template')
              
              begin
                apply_result = template_processor.apply_template(template_path, validated_path, options)
                
                # Convert to IterateCommandResult format
                result = Models::Result::IterateCommandResult.new(
                  success: true,
                  operation: "update_repo_template",
                  data: {
                    submodule_path: validated_path,
                    template_path: apply_result[:template_path],
                    target_path: apply_result[:target_path],
                    applied_template: apply_result[:applied_template],
                    output: apply_result[:output]
                  }
                )
              rescue => e
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "update_repo_template",
                  error_message: "Template application failed: #{e.message}"
                )
              end
              
              # Output result
              puts result.format_output(options[:format], options)
              result
            end
          end
          

        end
      end
    end
  end
end