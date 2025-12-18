# TemplateIteration Service
#
# This service handles the full template iteration process, including
# template application, folder comparison, and cleanup phase updates.

require_relative '../status_command_errors'
require_relative '../models/result/folder_analysis'
require_relative '../models/result/comparison_result'
require_relative '../models/result/iteration_result'
require_relative 'template_processor'

module GitTemplate
  module Services
    class TemplateIteration
      include StatusCommandErrors

      def initialize
        @template_processor = TemplateProcessor.new
      end

      def execute_repo_iteration(analysis, options = {})
        folder_analysis = analysis[:folder_analysis]
        folder_path = folder_analysis.path
        templated_folder_path = folder_analysis.templated_folder_path

        begin
          validate_iteration_prerequisites(analysis)
          
          # Execute the template iteration process
          iteration_result = @template_processor.iterate_template(folder_path, templated_folder_path)
          
          # Create detailed result
          create_iteration_result(folder_path, templated_folder_path, iteration_result, options)
        rescue => e
          raise TemplateProcessingError.new('execute_repo_iteration', e.message)
        end
      end

      def validate_iteration_prerequisites(analysis)
        folder_analysis = analysis[:folder_analysis]
        
        unless folder_analysis.exists
          raise FolderAnalysisError.new(folder_analysis.path, "Folder does not exist")
        end
        
        unless folder_analysis.has_template_configuration
          raise TemplateValidationError.new(folder_analysis.path, ["No template configuration found"])
        end
        
        unless folder_analysis.templated_folder_exists
          raise FolderAnalysisError.new(folder_analysis.templated_folder_path, "Templated folder does not exist")
        end
        
        unless folder_analysis.templated_has_configuration
          raise TemplateValidationError.new(folder_analysis.templated_folder_path, ["Templated folder lacks template configuration"])
        end
        
        # Validate template configurations if available
        if analysis[:template_configuration] && !analysis[:template_configuration][:valid]
          raise TemplateValidationError.new(folder_analysis.path, analysis[:template_configuration][:validation_errors])
        end
        
        if analysis[:templated_template_configuration] && !analysis[:templated_template_configuration][:valid]
          raise TemplateValidationError.new(folder_analysis.templated_folder_path, analysis[:templated_template_configuration][:validation_errors])
        end
      end

      def create_iteration_result(application_folder, templated_folder, iteration_result, options)
        # Generate comparison if requested
        comparison_result = nil
        if options[:detailed_comparison] || options[:generate_comparison]
          comparison_result = @template_processor.compare_folders(application_folder, templated_folder)
        end
        
        {
          success: iteration_result[:success],
          application_folder: application_folder,
          templated_folder: templated_folder,
          template_applied: iteration_result[:template_applied],
          differences_found: iteration_result[:differences_found],
          differences_count: iteration_result[:differences_count],
          cleanup_updated: iteration_result[:cleanup_updated],
          comparison_result: comparison_result,
          iteration_timestamp: Time.now,
          options_used: options
        }
      end

      def generate_iteration_report(iteration_result, format = :detailed)
        case format
        when :summary
          generate_summary_report(iteration_result)
        when :json
          iteration_result.to_json
        else
          generate_detailed_report(iteration_result)
        end
      end

      private

      def generate_detailed_report(result)
        output = []
        
        output << "=" * 80
        output << "Template Iteration Report".center(80)
        output << "=" * 80
        output << ""
        output << "Application Folder: #{result[:application_folder]}"
        output << "Templated Folder: #{result[:templated_folder]}"
        output << "Iteration Time: #{result[:iteration_timestamp].strftime('%Y-%m-%d %H:%M:%S')}"
        output << ""
        
        # Iteration Results
        output << "ITERATION RESULTS"
        output << "-" * 40
        output << "  Success: #{status_indicator(result[:success])}"
        output << "  Template Applied: #{status_indicator(result[:template_applied])}"
        output << "  Differences Found: #{status_indicator(result[:differences_found])}"
        output << "  Differences Count: #{result[:differences_count] || 0}"
        output << "  Cleanup Updated: #{status_indicator(result[:cleanup_updated])}"
        output << ""
        
        # Comparison Details
        if result[:comparison_result]
          comparison = result[:comparison_result]
          output << "COMPARISON DETAILS"
          output << "-" * 40
          output << "  Added Files: #{comparison.added_files.length}"
          output << "  Modified Files: #{comparison.modified_files.length}"
          output << "  Deleted Files: #{comparison.deleted_files.length}"
          output << "  Total Differences: #{comparison.total_differences}"
          output << ""
          
          if comparison.has_differences?
            output << "DIFFERENCES SUMMARY"
            output << "-" * 40
            
            comparison.added_files.first(5).each do |file|
              output << "  + #{file}"
            end
            
            comparison.modified_files.first(5).each do |file|
              output << "  ~ #{file}"
            end
            
            comparison.deleted_files.first(5).each do |file|
              output << "  - #{file}"
            end
            
            if comparison.total_differences > 15
              output << "  ... and #{comparison.total_differences - 15} more differences"
            end
            output << ""
          end
        end
        
        # Next Steps
        output << "NEXT STEPS"
        output << "-" * 40
        if result[:success]
          if result[:differences_found]
            output << "  1. Review the differences between application and templated folders"
            output << "  2. Run: git-template diff-result #{result[:application_folder]}"
            output << "  3. Adjust template configuration if needed"
            output << "  4. Run iteration again to refine the template"
          else
            output << "  1. Template iteration completed successfully"
            output << "  2. No differences found - template is complete"
            output << "  3. Consider running template validation tests"
          end
        else
          output << "  1. Review error messages above"
          output << "  2. Fix template configuration issues"
          output << "  3. Run: git-template status #{result[:application_folder]} for analysis"
        end
        
        output << ""
        output << "=" * 80
        
        output.join("\n")
      end

      def generate_summary_report(result)
        output = []
        
        output << "Template Iteration Summary"
        output << "=" * 40
        output << "Folder: #{File.basename(result[:application_folder])}"
        output << "Status: #{result[:success] ? 'Success' : 'Failed'}"
        output << "Differences: #{result[:differences_count] || 0}"
        output << "Cleanup Updated: #{result[:cleanup_updated] ? 'Yes' : 'No'}"
        
        if result[:success] && result[:differences_found]
          output << ""
          output << "Next: Review differences with diff-result command"
        elsif result[:success]
          output << ""
          output << "Template iteration completed successfully"
        end
        
        output.join("\n")
      end

      def status_indicator(value)
        value ? "✓" : "✗"
      end
    end
  end
end