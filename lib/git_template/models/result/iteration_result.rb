# IterationResult Model
#
# This class represents the result of a full template iteration,
# including application status, comparison results, and next steps.

require_relative 'base'
require_relative 'comparison_result'

module GitTemplate
  module Models
    module Result
      class IterationResult < Base
        attr_reader :application_folder, :templated_folder, :template_applied,
                    :differences_found, :differences_count, :cleanup_updated,
                    :comparison_result, :iteration_timestamp, :success

        def initialize(iteration_data)
          super()
          @success = iteration_data[:success]
          @application_folder = iteration_data[:application_folder]
          @templated_folder = iteration_data[:templated_folder]
          @template_applied = iteration_data[:template_applied]
          @differences_found = iteration_data[:differences_found]
          @differences_count = iteration_data[:differences_count] || 0
          @cleanup_updated = iteration_data[:cleanup_updated]
          @comparison_result = iteration_data[:comparison_result]
          @iteration_timestamp = iteration_data[:iteration_timestamp] || @timestamp
        end

        def summary
          {
            success: @success,
            application_folder: @application_folder,
            templated_folder: @templated_folder,
            template_applied: @template_applied,
            differences_found: @differences_found,
            differences_count: @differences_count,
            cleanup_updated: @cleanup_updated,
            has_comparison: !@comparison_result.nil?,
            iteration_timestamp: @iteration_timestamp
          }
        end

        def successful?
          @success
        end

        def has_differences?
          @differences_found
        end

        def complete?
          @success && !@differences_found
        end

        def needs_refinement?
          @success && @differences_found
        end

        def to_hash
          {
            success: @success,
            application_folder: @application_folder,
            templated_folder: @templated_folder,
            template_applied: @template_applied,
            differences_found: @differences_found,
            differences_count: @differences_count,
            cleanup_updated: @cleanup_updated,
            comparison_summary: @comparison_result&.summary,
            iteration_timestamp: @iteration_timestamp,
            timestamp: @timestamp
          }
        end

        # Override format methods for IterationResult-specific behavior
        def generate_detailed_report(options = {})
          output = []
          
          output << "=" * 80
          output << "Template Iteration Report".center(80)
          output << "=" * 80
          output << ""
          output << "Application Folder: #{@application_folder}"
          output << "Templated Folder: #{@templated_folder}"
          output << "Iteration Time: #{@iteration_timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
          output << ""
          
          # Iteration Results
          output << "ITERATION RESULTS"
          output << "-" * 40
          output << "  Success: #{status_indicator(@success)}"
          output << "  Template Applied: #{status_indicator(@template_applied)}"
          output << "  Differences Found: #{status_indicator(@differences_found)}"
          output << "  Differences Count: #{@differences_count}"
          output << "  Cleanup Updated: #{status_indicator(@cleanup_updated)}"
          output << ""
          
          # Comparison Details
          if @comparison_result
            output << "COMPARISON DETAILS"
            output << "-" * 40
            output << "  Added Files: #{@comparison_result.added_files.length}"
            output << "  Modified Files: #{@comparison_result.modified_files.length}"
            output << "  Deleted Files: #{@comparison_result.deleted_files.length}"
            output << "  Total Differences: #{@comparison_result.total_differences}"
            output << ""
            
            if @comparison_result.has_differences?
              output << "DIFFERENCES SUMMARY"
              output << "-" * 40
              
              @comparison_result.added_files.first(5).each do |file|
                output << "  + #{file}"
              end
              
              @comparison_result.modified_files.first(5).each do |file|
                output << "  ~ #{file}"
              end
              
              @comparison_result.deleted_files.first(5).each do |file|
                output << "  - #{file}"
              end
              
              if @comparison_result.total_differences > 15
                output << "  ... and #{@comparison_result.total_differences - 15} more differences"
              end
              output << ""
            end
          end
          
          # Next Steps
          output << "NEXT STEPS"
          output << "-" * 40
          if @success
            if @differences_found
              output << "  1. Review the differences between application and templated folders"
              output << "  2. Run: git-template diff-result #{@application_folder}"
              output << "  3. Adjust template configuration if needed"
              output << "  4. Run iteration again to refine the template"
            else
              output << "  1. Template iteration completed successfully"
              output << "  2. No differences found - template is complete"
              output << "  3. Consider running template validation tests"
            end
          else
            output << "  1. Review error messages"
            output << "  2. Fix template configuration issues"
            output << "  3. Run: git-template status #{@application_folder} for analysis"
          end
          
          output << ""
          output << "=" * 80
          
          output.join("\n")
        end

        def extract_folder_path
          @application_folder
        end

        # Override format_as_summary to use the iteration summary format
        def format_as_summary(options = {})
          output = []
          
          output << "Template Iteration Summary"
          output << "=" * 40
          output << "Folder: #{File.basename(@application_folder)}"
          output << "Status: #{successful? ? 'Success ✓' : 'Failed ✗'}"
          output << "Template Applied: #{@template_applied ? 'Yes ✓' : 'No ✗'}"
          output << "Differences Found: #{@differences_count}"
          output << "Cleanup Updated: #{@cleanup_updated ? 'Yes' : 'No'}"
          
          if successful?
            if has_differences?
              output << ""
              output << "Next Steps:"
              output << "  1. Review differences with: git-template diff-result #{@application_folder}"
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

        private

        def status_indicator(value)
          value ? "✓" : "✗"
        end
      end
    end
  end
end