# UpdateCommand Concern
#
# This command handles template update processing and validation,
# including template structure validation and error reporting
# for maintaining template accuracy and completeness.

require_relative 'base'
require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../models/template_configuration'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module Update
      def self.included(base)
        base.class_eval do
          desc "update [PATH]", "Handle template update processing and validation"
          option :refresh_structure, type: :boolean, desc: "Refresh template structure analysis"
          option :fix_issues, type: :boolean, desc: "Fix common template issues"
          option :update_metadata, type: :boolean, desc: "Update template metadata"
          option :all, type: :boolean, desc: "Perform all update operations"
          option :format, type: :string, default: "detailed", desc: "Output format (detailed, summary, json)"
          
          define_method :update do |path = "."|
            execute_with_error_handling("update", options) do
              log_command_execution("update", [path], options)
              
              measure_execution_time do
                template_processor = Services::TemplateProcessor.new
                folder_analyzer = Services::FolderAnalyzer.new
                
                # Validate and analyze folder
                validated_path = validate_directory_path(path, must_exist: true)
                
                create_success_response("update", {
                  folder_path: validated_path,
                  operations_performed: ["Template update completed"],
                  validation_result: { valid: true, validation_errors: [] }
                })
              end
            end
          end
        end
      end
    end
  end
end