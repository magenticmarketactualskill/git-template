# IterationStrategy Service
#
# This service determines the appropriate iteration strategy for template development
# based on folder analysis and provides recommendations for next steps.

require_relative '../status_command_errors'
require_relative '../models/result/folder_analysis'
require_relative '../models/result/iteration_strategy_result'

module GitTemplate
  module Services
    class IterationStrategy
      include StatusCommandErrors

      def initialize
        # Service is stateless, no initialization needed
      end

      def analyze_folder_for_iteration(folder_path, folder_analyzer = nil)
        folder_analyzer ||= FolderAnalyzer.new
        
        begin
          folder_analysis = folder_analyzer.analyze_folder(folder_path)
          template_development_status = folder_analyzer.analyze_template_development_status(folder_path)
          
          {
            folder_analysis: folder_analysis,
            development_status: template_development_status[:development_status],
            template_configuration: template_development_status[:template_configuration],
            templated_folder_analysis: template_development_status[:templated_folder_analysis],
            templated_template_configuration: template_development_status[:templated_template_configuration],
            recommendations: template_development_status[:recommendations]
          }
        rescue => e
          raise FolderAnalysisError.new(folder_path, e.message)
        end
      end

      def determine_iteration_strategy(analysis, options = {})
        folder_analysis = analysis[:folder_analysis]
        development_status = analysis[:development_status]
        
        strategy_data = case development_status
        when :ready_for_template_iteration
          {
            type: :repo_iteration,
            reason: "Folder is ready for template iteration",
            can_proceed: true,
            recommended_action: "Execute full template iteration process",
            prerequisites_met: true
          }
        when :template_folder_without_templated_version
          {
            type: :create_templated_folder,
            reason: "Template configuration exists but no templated version found",
            can_proceed: true,
            recommended_action: "Create templated folder and copy template configuration",
            prerequisites_met: false,
            missing_requirements: ["templated folder"]
          }
        when :templated_folder_missing_configuration
          {
            type: :template_iteration,
            reason: "Templated folder exists but lacks template configuration",
            can_proceed: true,
            recommended_action: "Copy template configuration to templated folder",
            prerequisites_met: false,
            missing_requirements: ["template configuration in templated folder"]
          }
        when :application_folder_ready_for_templating
          {
            type: :cannot_iterate,
            reason: "Application folder needs template configuration first",
            can_proceed: false,
            recommended_action: "Create template configuration: mkdir -p .git_template && touch .git_template/template.rb",
            prerequisites_met: false,
            missing_requirements: ["template configuration", "templated folder"]
          }
        when :folder_not_found
          {
            type: :cannot_iterate,
            reason: "Folder does not exist",
            can_proceed: false,
            recommended_action: "Create the folder first: mkdir -p #{folder_analysis.path}",
            prerequisites_met: false,
            missing_requirements: ["folder existence"]
          }
        when :not_template_project
          {
            type: :cannot_iterate,
            reason: "Folder is not set up for template development",
            can_proceed: false,
            recommended_action: "Initialize as template project or add template configuration",
            prerequisites_met: false,
            missing_requirements: ["git repository", "template configuration"]
          }
        else
          {
            type: :unknown_strategy,
            reason: "Cannot determine appropriate iteration strategy",
            can_proceed: false,
            recommended_action: "Review folder structure and run status command for detailed analysis",
            prerequisites_met: false,
            missing_requirements: ["manual review required"]
          }
        end
        
        # Create result object
        result = Models::Result::IterationStrategyResult.new(strategy_data, folder_analysis)
        
        # Add validation results
        validation_result = validate_iteration_prerequisites(analysis)
        result.add_validation_result(validation_result)
        
        # Add recommendations
        recommendations = get_iteration_recommendations(strategy_data.merge(folder_path: folder_analysis.path))
        result.add_recommendations(recommendations)
        
        result
      end

      def get_iteration_recommendations(strategy)
        recommendations = []
        
        case strategy[:type]
        when :repo_iteration
          recommendations << "Run: git-template iterate #{strategy[:folder_path]}"
          recommendations << "Review changes with: git-template diff-result #{strategy[:folder_path]}"
        when :create_templated_folder
          recommendations << "Create templated folder: git-template create-templated-folder #{strategy[:folder_path]}"
          recommendations << "Then run iteration: git-template iterate #{strategy[:folder_path]}"
        when :template_iteration
          recommendations << "Copy template configuration to templated folder"
          recommendations << "Then run iteration: git-template iterate #{strategy[:folder_path]}"
        when :cannot_iterate
          recommendations << strategy[:recommended_action]
          recommendations << "Then run: git-template status #{strategy[:folder_path]} to verify setup"
        else
          recommendations << "Run: git-template status #{strategy[:folder_path]} --format=json for detailed analysis"
          recommendations << "Review folder structure and template configuration"
        end
        
        recommendations
      end

      def validate_iteration_prerequisites(analysis)
        folder_analysis = analysis[:folder_analysis]
        development_status = analysis[:development_status]
        
        validation_result = {
          valid: false,
          errors: [],
          warnings: []
        }
        
        # Check basic folder existence
        unless folder_analysis.exists
          validation_result[:errors] << "Folder does not exist: #{folder_analysis.path}"
          return validation_result
        end
        
        # Check git repository
        unless folder_analysis.is_git_repository
          validation_result[:warnings] << "Folder is not a git repository"
        end
        
        # Check template configuration
        unless folder_analysis.has_template_configuration
          validation_result[:errors] << "No template configuration found"
        end
        
        # Check templated folder
        unless folder_analysis.templated_folder_exists
          validation_result[:errors] << "No templated folder found"
        end
        
        # Check templated folder configuration
        unless folder_analysis.templated_has_configuration
          validation_result[:errors] << "Templated folder lacks template configuration"
        end
        
        # Validate template configurations if they exist
        if analysis[:template_configuration] && !analysis[:template_configuration][:valid]
          validation_result[:errors] << "Main template configuration is invalid"
          validation_result[:errors].concat(analysis[:template_configuration][:validation_errors])
        end
        
        if analysis[:templated_template_configuration] && !analysis[:templated_template_configuration][:valid]
          validation_result[:errors] << "Templated template configuration is invalid"
          validation_result[:errors].concat(analysis[:templated_template_configuration][:validation_errors])
        end
        
        validation_result[:valid] = validation_result[:errors].empty?
        validation_result
      end
    end
  end
end