# StrategyCommand Concern
#
# This command analyzes and reports on iteration strategies for template development,
# providing detailed analysis of what actions can be taken and prerequisites needed.

require_relative 'base'
require_relative '../services/folder_analyzer'
require_relative '../services/iteration_strategy'

module GitTemplate
  module Command
    module Strategy
      def self.included(base)
        base.class_eval do
          
          desc "strategy [PATH]", "Analyze iteration strategy for template development"
          option :format, type: :string, default: "detailed", desc: "Output format: detailed, summary, json"
          option :verbose, type: :boolean, default: false, desc: "Show verbose output"
          option :debug, type: :boolean, default: false, desc: "Show debug information"
          option :validate, type: :boolean, default: true, desc: "Include validation checks"
          
          define_method :strategy do |folder_path = "."|
            execute_with_error_handling("strategy", options) do
              log_command_execution("strategy", [folder_path], options)
              
              measure_execution_time do
                setup_environment(options)
                
                # Validate and analyze folder
                validated_path = validate_directory_path(folder_path, must_exist: false)
                
                # Analyze iteration strategy
                result = analyze_iteration_strategy(validated_path, options)
                
                # Output based on format
                formatted_result = result.format_output(options[:format], options)
                
                case options[:format]
                when "json"
                  puts JSON.pretty_generate(formatted_result)
                when "summary"
                  puts format_strategy_summary(result)
                else
                  puts formatted_result[:data][:report]
                end
                
                formatted_result
              end
            end
          end
          
          private
          
          define_method :setup_environment do |opts|
            ENV['VERBOSE'] = '1' if opts[:verbose]
            ENV['DEBUG'] = '1' if opts[:debug]
          end
          
          define_method :analyze_iteration_strategy do |folder_path, options|
            folder_analyzer = Services::FolderAnalyzer.new
            iteration_strategy_service = Services::IterationStrategy.new
            
            # Analyze folder for iteration
            analysis = iteration_strategy_service.analyze_folder_for_iteration(folder_path, folder_analyzer)
            
            # Determine iteration strategy
            strategy_result = iteration_strategy_service.determine_iteration_strategy(analysis, options)
            
            strategy_result
          end
          
          define_method :format_strategy_summary do |strategy_result|
            output = []
            
            output << "Strategy Analysis Summary"
            output << "=" * 40
            output << "Folder: #{strategy_result.extract_folder_path}"
            output << "Strategy: #{strategy_result.strategy_type.to_s.split('_').map(&:capitalize).join(' ')}"
            output << "Can Proceed: #{strategy_result.can_proceed ? '✓' : '✗'}"
            output << "Prerequisites Met: #{strategy_result.prerequisites_met ? '✓' : '✗'}"
            
            if strategy_result.missing_requirements.any?
              output << ""
              output << "Missing Requirements:"
              strategy_result.missing_requirements.each { |req| output << "  - #{req}" }
            end
            
            if strategy_result.recommendations.any?
              output << ""
              output << "Next Steps:"
              strategy_result.recommendations.first(3).each_with_index do |rec, index|
                output << "  #{index + 1}. #{rec}"
              end
            end
            
            output.join("\n")
          end
        end
      end
    end
  end
end