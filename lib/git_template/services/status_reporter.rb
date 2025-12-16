# StatusReporter Service
#
# This service generates structured status reports for folder analysis,
# providing formatted output for analysis results and development recommendations.

require_relative '../status_command_errors'

module GitTemplate
  module Services
    class StatusReporter
      include StatusCommandErrors

      def initialize
        # Service is stateless, no initialization needed
      end

      def generate_report(analysis_data)
        begin
          report = {
            header: generate_header(analysis_data),
            folder_status: generate_folder_status(analysis_data),
            template_status: generate_template_status(analysis_data),
            development_status: generate_development_status(analysis_data),
            recommendations: generate_recommendations_section(analysis_data),
            footer: generate_footer(analysis_data)
          }
          
          format_report(report)
        rescue => e
          raise StatusCommandError.new("Failed to generate status report: #{e.message}")
        end
      end

      def format_findings(findings)
        output = []
        
        findings.each do |key, value|
          case key
          when :folder_analysis
            output << format_folder_analysis(value)
          when :template_configuration
            output << format_template_configuration(value)
          when :templated_folder_analysis
            output << format_templated_folder_analysis(value)
          when :development_status
            output << format_development_status(value)
          when :recommendations
            output << format_recommendations(value)
          end
        end
        
        output.join("\n\n")
      end

      def generate_summary_report(multiple_analyses)
        summary = {
          total_folders: multiple_analyses.length,
          ready_for_iteration: 0,
          needs_setup: 0,
          has_issues: 0
        }
        
        multiple_analyses.each do |analysis|
          case analysis[:development_status]
          when :ready_for_template_iteration
            summary[:ready_for_iteration] += 1
          when :folder_not_found, :not_template_project
            summary[:needs_setup] += 1
          else
            summary[:has_issues] += 1
          end
        end
        
        format_summary_report(summary, multiple_analyses)
      end

      private

      def generate_header(analysis_data)
        folder_path = analysis_data.dig(:folder_analysis, :path) || 'Unknown'
        timestamp = analysis_data.dig(:folder_analysis, :analysis_timestamp) || Time.now
        
        {
          title: "Git Template Status Report",
          folder: folder_path,
          timestamp: timestamp.strftime("%Y-%m-%d %H:%M:%S")
        }
      end

      def generate_folder_status(analysis_data)
        folder_analysis = analysis_data[:folder_analysis] || {}
        
        {
          exists: folder_analysis[:exists] || false,
          is_git_repository: folder_analysis[:is_git_repository] || false,
          has_template_configuration: folder_analysis[:has_template_configuration] || false,
          templated_folder_exists: folder_analysis[:templated_folder_exists] || false,
          templated_folder_path: folder_analysis[:templated_folder_path]
        }
      end

      def generate_template_status(analysis_data)
        template_config = analysis_data[:template_configuration]
        templated_config = analysis_data[:templated_template_configuration]
        
        status = {}
        
        if template_config
          status[:main_template] = {
            valid: template_config[:valid],
            validation_errors: template_config[:validation_errors] || [],
            lifecycle_phases: template_config[:lifecycle_phases] || [],
            has_cleanup_phase: template_config[:has_cleanup_phase] || false
          }
        end
        
        if templated_config
          status[:templated_template] = {
            valid: templated_config[:valid],
            validation_errors: templated_config[:validation_errors] || [],
            lifecycle_phases: templated_config[:lifecycle_phases] || [],
            has_cleanup_phase: templated_config[:has_cleanup_phase] || false
          }
        end
        
        status
      end

      def generate_development_status(analysis_data)
        {
          status: analysis_data[:development_status] || :unknown_status,
          description: get_status_description(analysis_data[:development_status])
        }
      end

      def generate_recommendations_section(analysis_data)
        analysis_data[:recommendations] || []
      end

      def generate_footer(analysis_data)
        version = begin
          GitTemplate::VERSION
        rescue
          "unknown"
        end
        
        {
          generated_by: "git-template status command",
          version: version
        }
      end

      def format_report(report)
        output = []
        
        # Header
        output << "=" * 80
        output << report[:header][:title].center(80)
        output << "=" * 80
        output << ""
        output << "Folder: #{report[:header][:folder]}"
        output << "Generated: #{report[:header][:timestamp]}"
        output << ""
        
        # Folder Status
        output << "FOLDER STATUS"
        output << "-" * 40
        folder_status = report[:folder_status]
        output << "  Exists: #{status_indicator(folder_status[:exists])}"
        output << "  Git Repository: #{status_indicator(folder_status[:is_git_repository])}"
        output << "  Template Configuration: #{status_indicator(folder_status[:has_template_configuration])}"
        output << "  Templated Folder: #{status_indicator(folder_status[:templated_folder_exists])}"
        
        if folder_status[:templated_folder_path]
          output << "  Templated Folder Path: #{folder_status[:templated_folder_path]}"
        end
        output << ""
        
        # Template Status
        if report[:template_status].any?
          output << "TEMPLATE STATUS"
          output << "-" * 40
          
          if report[:template_status][:main_template]
            main = report[:template_status][:main_template]
            output << "  Main Template:"
            output << "    Valid: #{status_indicator(main[:valid])}"
            output << "    Lifecycle Phases: #{main[:lifecycle_phases].length}"
            output << "    Has Cleanup Phase: #{status_indicator(main[:has_cleanup_phase])}"
            
            if main[:validation_errors].any?
              output << "    Validation Errors:"
              main[:validation_errors].each { |error| output << "      - #{error}" }
            end
          end
          
          if report[:template_status][:templated_template]
            templated = report[:template_status][:templated_template]
            output << "  Templated Template:"
            output << "    Valid: #{status_indicator(templated[:valid])}"
            output << "    Lifecycle Phases: #{templated[:lifecycle_phases].length}"
            output << "    Has Cleanup Phase: #{status_indicator(templated[:has_cleanup_phase])}"
            
            if templated[:validation_errors].any?
              output << "    Validation Errors:"
              templated[:validation_errors].each { |error| output << "      - #{error}" }
            end
          end
          output << ""
        end
        
        # Development Status
        output << "DEVELOPMENT STATUS"
        output << "-" * 40
        dev_status = report[:development_status]
        output << "  Status: #{format_status_name(dev_status[:status])}"
        output << "  Description: #{dev_status[:description]}"
        output << ""
        
        # Recommendations
        if report[:recommendations].any?
          output << "RECOMMENDATIONS"
          output << "-" * 40
          report[:recommendations].each_with_index do |rec, index|
            output << "  #{index + 1}. #{rec}"
          end
          output << ""
        end
        
        # Footer
        output << "-" * 80
        output << "Generated by #{report[:footer][:generated_by]} v#{report[:footer][:version]}"
        output << "=" * 80
        
        output.join("\n")
      end

      def format_summary_report(summary, analyses)
        output = []
        
        output << "=" * 80
        output << "Git Template Summary Report".center(80)
        output << "=" * 80
        output << ""
        output << "SUMMARY"
        output << "-" * 40
        output << "  Total Folders Analyzed: #{summary[:total_folders]}"
        output << "  Ready for Iteration: #{summary[:ready_for_iteration]}"
        output << "  Need Setup: #{summary[:needs_setup]}"
        output << "  Have Issues: #{summary[:has_issues]}"
        output << ""
        
        if analyses.any?
          output << "DETAILED RESULTS"
          output << "-" * 40
          analyses.each_with_index do |analysis, index|
            folder_path = analysis.dig(:folder_analysis, :path) || "Folder #{index + 1}"
            status = analysis[:development_status] || :unknown_status
            output << "  #{index + 1}. #{File.basename(folder_path)}: #{format_status_name(status)}"
          end
        end
        
        output << ""
        output << "=" * 80
        
        output.join("\n")
      end

      def status_indicator(value)
        value ? "✓" : "✗"
      end

      def format_status_name(status)
        status.to_s.split('_').map(&:capitalize).join(' ')
      end

      def get_status_description(status)
        case status
        when :folder_not_found
          "The specified folder does not exist"
        when :not_template_project
          "Folder exists but is not set up for template development"
        when :application_folder_ready_for_templating
          "Application folder is ready to have templates created"
        when :template_folder_without_templated_version
          "Has template configuration but no templated version for testing"
        when :templated_folder_missing_configuration
          "Templated folder exists but lacks template configuration"
        when :ready_for_template_iteration
          "Ready for template iteration and refinement"
        else
          "Status requires manual review"
        end
      end

      def format_folder_analysis(analysis)
        lines = ["Folder Analysis:"]
        lines << "  Path: #{analysis[:path]}"
        lines << "  Exists: #{status_indicator(analysis[:exists])}"
        lines << "  Git Repository: #{status_indicator(analysis[:is_git_repository])}"
        lines << "  Template Configuration: #{status_indicator(analysis[:has_template_configuration])}"
        lines.join("\n")
      end

      def format_template_configuration(config)
        lines = ["Template Configuration:"]
        lines << "  Valid: #{status_indicator(config[:valid])}"
        lines << "  Lifecycle Phases: #{config[:lifecycle_phases].length}"
        lines << "  Has Cleanup Phase: #{status_indicator(config[:has_cleanup_phase])}"
        
        if config[:validation_errors].any?
          lines << "  Validation Errors:"
          config[:validation_errors].each { |error| lines << "    - #{error}" }
        end
        
        lines.join("\n")
      end

      def format_templated_folder_analysis(analysis)
        lines = ["Templated Folder Analysis:"]
        lines << "  Path: #{analysis[:path]}"
        lines << "  Exists: #{status_indicator(analysis[:exists])}"
        lines << "  Template Configuration: #{status_indicator(analysis[:has_template_configuration])}"
        lines.join("\n")
      end

      def format_development_status(status)
        "Development Status: #{format_status_name(status)}"
      end

      def format_recommendations(recommendations)
        lines = ["Recommendations:"]
        recommendations.each_with_index do |rec, index|
          lines << "  #{index + 1}. #{rec}"
        end
        lines.join("\n")
      end
    end
  end
end