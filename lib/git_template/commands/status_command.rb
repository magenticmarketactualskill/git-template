# StatusCommand Class
#
# This command provides comprehensive status analysis for application folders,
# including template configuration detection, git repository status, and
# development workflow recommendations.

require_relative '../services/folder_analyzer'
require_relative '../services/status_reporter'
require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class StatusCommand
      include StatusCommandErrors

      def initialize
        @folder_analyzer = Services::FolderAnalyzer.new
        @status_reporter = Services::StatusReporter.new
      end

      def execute(folder_path, options = {})
        begin
          # Validate input
          validate_folder_path(folder_path)
          
          # Analyze folder
          analysis_data = @folder_analyzer.analyze_template_development_status(folder_path)
          
          # Generate report
          if options[:format] == :json
            generate_json_report(analysis_data)
          elsif options[:format] == :summary
            generate_summary_report(analysis_data)
          else
            generate_detailed_report(analysis_data)
          end
          
        rescue StatusCommandError => e
          handle_status_error(e, options)
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def execute_multiple(folder_paths, options = {})
        begin
          analyses = []
          errors = []
          
          folder_paths.each do |folder_path|
            begin
              analysis_data = @folder_analyzer.analyze_template_development_status(folder_path)
              analyses << analysis_data
            rescue StatusCommandError => e
              errors << { folder: folder_path, error: e.message }
            end
          end
          
          # Generate summary report
          if options[:format] == :json
            {
              success: true,
              analyses: analyses,
              errors: errors,
              summary: generate_analyses_summary(analyses)
            }
          else
            report = @status_reporter.generate_summary_report(analyses)
            
            if errors.any?
              report += "\n\nERRORS:\n"
              errors.each { |error| report += "  #{error[:folder]}: #{error[:error]}\n" }
            end
            
            { success: true, report: report }
          end
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def check_folder_status(folder_path)
        # Quick status check without full analysis
        begin
          analysis = @folder_analyzer.analyze_folder(folder_path)
          
          {
            exists: analysis.exists,
            is_git_repository: analysis.is_git_repository,
            has_template_configuration: analysis.has_template_configuration,
            templated_folder_exists: analysis.templated_folder_exists,
            ready_for_iteration: analysis.ready_for_iteration?
          }
        rescue => e
          {
            exists: false,
            error: e.message
          }
        end
      end

      def validate_template_setup(folder_path)
        # Validate that folder is properly set up for template development
        begin
          analysis_data = @folder_analyzer.analyze_template_development_status(folder_path)
          
          validation_results = {
            valid_setup: false,
            issues: [],
            recommendations: analysis_data[:recommendations] || []
          }
          
          # Check for common setup issues
          folder_analysis = analysis_data[:folder_analysis]
          
          unless folder_analysis[:exists]
            validation_results[:issues] << "Folder does not exist"
            return validation_results
          end
          
          unless folder_analysis[:is_git_repository] || folder_analysis[:has_template_configuration]
            validation_results[:issues] << "Folder is not a git repository and has no template configuration"
          end
          
          if folder_analysis[:has_template_configuration]
            template_config = analysis_data[:template_configuration]
            if template_config && !template_config[:valid]
              validation_results[:issues] << "Template configuration is invalid"
              validation_results[:issues].concat(template_config[:validation_errors])
            end
          end
          
          if folder_analysis[:templated_folder_exists] && !folder_analysis[:templated_has_configuration]
            validation_results[:issues] << "Templated folder exists but lacks template configuration"
          end
          
          validation_results[:valid_setup] = validation_results[:issues].empty?
          validation_results
          
        rescue => e
          {
            valid_setup: false,
            issues: ["Failed to validate setup: #{e.message}"],
            recommendations: []
          }
        end
      end

      private

      def validate_folder_path(folder_path)
        if folder_path.nil? || folder_path.strip.empty?
          raise InvalidPathError.new("Folder path cannot be empty")
        end
        
        # Expand path to handle relative paths and ~
        expanded_path = File.expand_path(folder_path)
        
        # Check if parent directory exists (folder itself may not exist yet)
        parent_dir = File.dirname(expanded_path)
        unless File.directory?(parent_dir)
          raise InvalidPathError.new("Parent directory does not exist: #{parent_dir}")
        end
        
        expanded_path
      end

      def generate_detailed_report(analysis_data)
        report = @status_reporter.generate_report(analysis_data)
        { success: true, report: report, analysis_data: analysis_data }
      end

      def generate_summary_report(analysis_data)
        folder_analysis = analysis_data[:folder_analysis]
        development_status = analysis_data[:development_status]
        
        summary = {
          folder: folder_analysis[:path],
          status: development_status,
          exists: folder_analysis[:exists],
          git_repository: folder_analysis[:is_git_repository],
          template_configuration: folder_analysis[:has_template_configuration],
          templated_folder: folder_analysis[:templated_folder_exists],
          ready_for_iteration: development_status == :ready_for_template_iteration
        }
        
        { success: true, summary: summary }
      end

      def generate_json_report(analysis_data)
        {
          success: true,
          timestamp: Time.now.iso8601,
          analysis: analysis_data
        }
      end

      def generate_analyses_summary(analyses)
        {
          total: analyses.length,
          ready_for_iteration: analyses.count { |a| a[:development_status] == :ready_for_template_iteration },
          need_setup: analyses.count { |a| [:folder_not_found, :not_template_project].include?(a[:development_status]) },
          have_issues: analyses.count { |a| ![:ready_for_template_iteration, :folder_not_found, :not_template_project].include?(a[:development_status]) }
        }
      end

      def handle_status_error(error, options)
        if options[:format] == :json
          {
            success: false,
            error: error.message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: "Status command failed: #{error.message}"
          }
        end
      end

      def handle_unexpected_error(error, options)
        error_message = "Unexpected error during status analysis: #{error.message}"
        
        if options[:debug]
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        if options[:format] == :json
          {
            success: false,
            error: error_message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: error_message
          }
        end
      end
    end
  end
end