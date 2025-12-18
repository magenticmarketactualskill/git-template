# IterationStrategyResult Model
#
# This class represents the result of analyzing iteration strategy,
# including the determined strategy, prerequisites, and recommendations.

require_relative 'base'

module GitTemplate
  module Models
    module Result
      class IterationStrategyResult < Base
        attr_reader :strategy_type, :reason, :can_proceed, :recommended_action,
                    :prerequisites_met, :missing_requirements, :folder_analysis,
                    :validation_result, :recommendations

        def initialize(strategy_data, folder_analysis = nil)
          super()
          @strategy_type = strategy_data[:type]
          @reason = strategy_data[:reason]
          @can_proceed = strategy_data[:can_proceed]
          @recommended_action = strategy_data[:recommended_action]
          @prerequisites_met = strategy_data[:prerequisites_met]
          @missing_requirements = strategy_data[:missing_requirements] || []
          @folder_analysis = folder_analysis
          @validation_result = nil
          @recommendations = []
        end

        def add_validation_result(validation_result)
          @validation_result = validation_result
        end

        def add_recommendations(recommendations)
          @recommendations = recommendations
        end

        def summary
          {
            strategy_type: @strategy_type,
            can_proceed: @can_proceed,
            prerequisites_met: @prerequisites_met,
            missing_requirements_count: @missing_requirements.length,
            has_validation_errors: @validation_result&.dig(:errors)&.any? || false,
            has_warnings: @validation_result&.dig(:warnings)&.any? || false,
            recommendations_count: @recommendations.length,
            folder_path: extract_folder_path,
            analysis_timestamp: @timestamp
          }
        end

        def ready_for_iteration?
          @strategy_type == :repo_iteration && @can_proceed && @prerequisites_met
        end

        def needs_setup?
          @strategy_type == :cannot_iterate || !@prerequisites_met
        end

        def has_errors?
          @validation_result&.dig(:errors)&.any? || false
        end

        def has_warnings?
          @validation_result&.dig(:warnings)&.any? || false
        end

        def to_hash
          {
            strategy_type: @strategy_type,
            reason: @reason,
            can_proceed: @can_proceed,
            recommended_action: @recommended_action,
            prerequisites_met: @prerequisites_met,
            missing_requirements: @missing_requirements,
            validation_result: @validation_result,
            recommendations: @recommendations,
            folder_analysis: @folder_analysis&.status_summary,
            timestamp: @timestamp
          }
        end

        # Override format methods for IterationStrategyResult-specific behavior
        def generate_detailed_report(options = {})
          output = []
          
          output << "=" * 80
          output << "Template Iteration Strategy Analysis".center(80)
          output << "=" * 80
          output << ""
          output << "Folder: #{extract_folder_path}"
          output << "Generated: #{@timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
          output << ""
          
          # Strategy Information
          output << "ITERATION STRATEGY"
          output << "-" * 40
          output << "  Strategy Type: #{format_strategy_name(@strategy_type)}"
          output << "  Can Proceed: #{status_indicator(@can_proceed)}"
          output << "  Prerequisites Met: #{status_indicator(@prerequisites_met)}"
          output << "  Reason: #{@reason}"
          output << ""
          
          # Missing Requirements
          if @missing_requirements.any?
            output << "MISSING REQUIREMENTS"
            output << "-" * 40
            @missing_requirements.each_with_index do |req, index|
              output << "  #{index + 1}. #{req}"
            end
            output << ""
          end
          
          # Validation Results
          if @validation_result
            output << "VALIDATION RESULTS"
            output << "-" * 40
            output << "  Valid: #{status_indicator(@validation_result[:valid])}"
            
            if @validation_result[:errors].any?
              output << "  Errors:"
              @validation_result[:errors].each { |error| output << "    - #{error}" }
            end
            
            if @validation_result[:warnings].any?
              output << "  Warnings:"
              @validation_result[:warnings].each { |warning| output << "    - #{warning}" }
            end
            output << ""
          end
          
          # Recommendations
          if @recommendations.any?
            output << "RECOMMENDATIONS"
            output << "-" * 40
            @recommendations.each_with_index do |rec, index|
              output << "  #{index + 1}. #{rec}"
            end
            output << ""
          end
          
          # Next Steps
          output << "NEXT STEPS"
          output << "-" * 40
          output << "  #{@recommended_action}"
          output << ""
          
          output << "=" * 80
          
          output.join("\n")
        end

        def extract_folder_path
          @folder_analysis&.path || "Unknown path"
        end

        private

        def status_indicator(value)
          value ? "✓" : "✗"
        end

        def format_strategy_name(strategy)
          strategy.to_s.split('_').map(&:capitalize).join(' ')
        end
      end
    end
  end
end