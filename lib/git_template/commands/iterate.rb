# IterateCommand Concern
#
# This command handles template iteration with configuration preservation,
# template application and comparison functionality, integrating with
# TemplateProcessor service for the iterative template development process.

require_relative 'base'
require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module Iterate
      def self.included(base)
        base.class_eval do
          desc "iterate [PATH]", "Handle template iteration with configuration preservation"
          option :create_templated_folder, type: :boolean, desc: "Create templated folder if it doesn't exist"
          option :detailed_comparison, type: :boolean, desc: "Generate detailed comparison report"
          option :format, type: :string, default: "detailed", desc: "Output format (detailed, summary, json)"
          
          define_method :iterate do |path = "."|
            execute_with_error_handling("iterate", options) do
              log_command_execution("iterate", [path], options)
              
              measure_execution_time do
                template_processor = Services::TemplateProcessor.new
                folder_analyzer = Services::FolderAnalyzer.new
                
                # Validate and analyze folder
                validated_path = validate_directory_path(path, must_exist: true)
                analysis = analyze_folder_for_iteration(validated_path, folder_analyzer)
                
                # Determine iteration strategy
                iteration_strategy = determine_iteration_strategy(analysis, options)
                
                # Execute iteration based on strategy
                case iteration_strategy[:type]
                when :full_iteration
                  execute_full_iteration(analysis, template_processor, options)
                when :create_templated_folder
                  execute_create_templated_folder(analysis, template_processor, options)
                when :template_only_update
                  execute_template_only_update(analysis, template_processor, options)
                else
                  raise StatusCommandError.new("Cannot iterate: #{iteration_strategy[:reason]}")
                end
              end
            end
          end
        end
      end
    end
  end
end