# RerunTemplateCommand Concern
#
# This command reruns template processing on an existing templated folder,
# updating the template configuration based on the current folder state.

require_relative 'base'
require_relative 'submodule_protection'
require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module RerunTemplate
      def self.included(base)
        base.class_eval do
          include SubmoduleProtection
          desc "rerun-template", "Rerun template processing and update template configuration"
          add_common_options
          option :update_content, type: :boolean, default: true, desc: "Update template content based on current state"
          option :path, type: :string, default: ".", desc: "Templated folder path (defaults to current directory)"
          
          define_method :rerun_template do
            execute_with_error_handling("rerun_template", options) do
              path = options[:path] || "."
              log_command_execution("rerun_template", [path], options)
              setup_environment(options)
              
              # Check if path is a submodule - if so, reject the operation
              protection_result = check_submodule_protection(path, "rerun_template")
              if protection_result
                puts protection_result.format_output(options[:format], options)
                return protection_result
              end
              
              template_processor = Services::TemplateProcessor.new
              folder_analyzer = Services::FolderAnalyzer.new
              
              # Validate templated folder
              validated_path = validate_directory_path(path, must_exist: true)
              
              # Analyze folder to ensure it has template configuration
              analysis = folder_analyzer.analyze_template_development_status(validated_path)
              folder_analysis = analysis[:folder_analysis]
              
              # Check if folder has template configuration
              unless folder_analysis[:has_template_configuration]
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "rerun_template",
                  error_message: "No template configuration found at #{validated_path}. Use create-templated-folder first."
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Apply template to regenerate application files
              template_path = File.join(validated_path, '.git_template')
              
              begin
                apply_result = template_processor.apply_template(template_path, validated_path, options)
                
                # Check if template application was successful
                if apply_result[:success]
                  result = Models::Result::IterateCommandResult.new(
                    success: true,
                    operation: "rerun_template",
                    data: {
                      template_path: apply_result[:template_path],
                      target_path: apply_result[:target_path],
                      applied_template: apply_result[:applied_template],
                      output: apply_result[:output]
                    }
                  )
                else
                  result = Models::Result::IterateCommandResult.new(
                    success: false,
                    operation: "rerun_template",
                    error_message: "Template execution failed",
                    data: {
                      template_path: apply_result[:template_path],
                      target_path: apply_result[:target_path],
                      applied_template: apply_result[:applied_template],
                      output: apply_result[:output]
                    }
                  )
                end
              rescue => e
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "rerun_template",
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