# FolderAnalyzer Service
#
# This service provides comprehensive folder analysis functionality,
# including detection of template configurations, git repositories,
# and corresponding templated folders.

require_relative '../models/folder_analysis'
require_relative '../models/template_configuration'
require_relative '../models/templater_folder'
require_relative '../status_command_errors'

module GitTemplate
  module Services
    class FolderAnalyzer
      include StatusCommandErrors

      def initialize
        # Service is stateless, no initialization needed
      end

      def analyze_folder(path)
        begin
          Models::FolderAnalysis.new(path)
        rescue => e
          raise FolderAnalysisError.new(path, e.message)
        end
      end

      def has_template_configuration?(path)
        Models::TemplaterFolder.new(path).has_template_configuration?
      end

      def is_git_repository?(path)
        Models::TemplaterFolder.new(path).git_repository?
      end

      def find_templated_folder(path)
        Models::TemplaterFolder.new(path).templated_folder_path
      end

      def get_template_configuration(path)
        templater_folder = Models::TemplaterFolder.new(path)
        return nil unless templater_folder.has_template_configuration?
        
        begin
          Models::TemplateConfiguration.new(templater_folder.template_configuration_path)
        rescue => e
          raise TemplateValidationError.new(templater_folder.template_configuration_path, [e.message])
        end
      end

      def analyze_template_development_status(path)
        analysis = analyze_folder(path)
        
        status = {
          folder_analysis: analysis.status_summary,
          development_status: determine_development_status(analysis),
          recommendations: generate_recommendations(analysis)
        }
        
        # Add template configuration details if available
        if analysis.has_template_configuration
          begin
            template_config = get_template_configuration(path)
            status[:template_configuration] = {
              valid: template_config.valid?,
              validation_errors: template_config.validation_errors,
              lifecycle_phases: template_config.lifecycle_phases,
              has_cleanup_phase: !template_config.cleanup_phase.nil?
            }
          rescue TemplateValidationError => e
            status[:template_configuration] = {
              valid: false,
              validation_errors: [e.message],
              lifecycle_phases: [],
              has_cleanup_phase: false
            }
          end
        end
        
        # Add templated folder analysis if it exists
        if analysis.templated_folder_exists
          templated_analysis = analyze_folder(analysis.templated_folder_path)
          status[:templated_folder_analysis] = templated_analysis.status_summary
          
          if templated_analysis.has_template_configuration
            begin
              templated_config = get_template_configuration(analysis.templated_folder_path)
              status[:templated_template_configuration] = {
                valid: templated_config.valid?,
                validation_errors: templated_config.validation_errors,
                lifecycle_phases: templated_config.lifecycle_phases,
                has_cleanup_phase: !templated_config.cleanup_phase.nil?
              }
            rescue TemplateValidationError => e
              status[:templated_template_configuration] = {
                valid: false,
                validation_errors: [e.message],
                lifecycle_phases: [],
                has_cleanup_phase: false
              }
            end
          end
        end
        
        status
      end

      private

      def determine_development_status(analysis)
        if !analysis.exists
          :folder_not_found
        elsif !analysis.is_git_repository && !analysis.has_template_configuration
          :not_template_project
        elsif analysis.is_git_repository && !analysis.has_template_configuration && !analysis.templated_folder_exists
          :application_folder_ready_for_templating
        elsif analysis.has_template_configuration && !analysis.templated_folder_exists
          :template_folder_without_templated_version
        elsif analysis.templated_folder_exists && !analysis.templated_has_configuration
          :templated_folder_missing_configuration
        elsif analysis.ready_for_iteration?
          :ready_for_template_iteration
        else
          :unknown_status
        end
      end

      def generate_recommendations(analysis)
        recommendations = []
        folder_path = analysis.path
        
        case determine_development_status(analysis)
        when :folder_not_found
          recommendations << "Create the folder: mkdir -p \"#{folder_path}\""
          recommendations << "Or verify the path is correct"
        when :not_template_project
          if !analysis.is_git_repository
            recommendations << "Initialize as git repository: cd \"#{folder_path}\" && git init"
          end
          recommendations << "Or add template configuration: mkdir -p \"#{folder_path}/.git_template\""
        when :application_folder_ready_for_templating
          # Calculate the templated folder path
          relative_path = get_relative_path_for_templated(folder_path)
          templated_path = "templated/#{relative_path}"
          recommendations << "Create templated folder: git-template iterate \"#{folder_path}\" --create-templated-folder"
          recommendations << "Or manually: mkdir -p \"#{templated_path}/.git_template\""
          recommendations << "Then create template: touch \"#{templated_path}/.git_template/template.rb\""
        when :template_folder_without_templated_version
          relative_path = get_relative_path_for_templated(folder_path)
          templated_path = "templated/#{relative_path}"
          recommendations << "Create templated version: git-template iterate \"#{folder_path}\" --create-templated-folder"
          recommendations << "Or manually: mkdir -p \"#{templated_path}/.git_template\""
        when :templated_folder_missing_configuration
          templated_folder = analysis.templated_folder_path
          recommendations << "Add template configuration: mkdir -p \"#{templated_folder}/.git_template\""
          recommendations << "Create template file: touch \"#{templated_folder}/.git_template/template.rb\""
        when :ready_for_template_iteration
          recommendations << "Run template iteration: git-template iterate \"#{folder_path}\""
          recommendations << "Check differences: git-template diff_result \"#{folder_path}\""
        else
          recommendations << "Review folder structure and template configuration"
          recommendations << "Run: git-template status \"#{folder_path}\" --format=json for detailed analysis"
        end
        
        recommendations
      end

      private

      def get_relative_path_for_templated(folder_path)
        current_dir = Dir.pwd
        expanded_path = File.expand_path(folder_path)
        
        # If expanded_path is absolute and starts with current_dir, make it relative
        if expanded_path.start_with?(current_dir)
          relative_path = expanded_path[(current_dir.length + 1)..-1] # +1 to skip the '/'
        else
          # If it's already relative or doesn't start with current_dir, use as-is
          relative_path = folder_path.start_with?('/') ? File.basename(folder_path) : folder_path
        end
        
        relative_path
      end
    end
  end
end