# FolderAnalyzer Service
#
# This service provides comprehensive folder analysis functionality,
# including detection of template configurations, git repositories,
# and corresponding templated folders.

require_relative '../models/folder_analysis'
require_relative '../models/template_configuration'
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
        return false unless File.directory?(path)
        File.directory?(File.join(path, '.git_template'))
      end

      def is_git_repository?(path)
        return false unless File.directory?(path)
        File.directory?(File.join(path, '.git'))
      end

      def find_templated_folder(path)
        return nil unless File.directory?(path)
        
        parent_dir = File.dirname(path)
        folder_name = File.basename(path)
        
        # Try different templated folder naming patterns
        templated_patterns = [
          "#{folder_name}-templated",
          "#{folder_name}-templatd"  # Handle typo in existing examples
        ]
        
        templated_patterns.each do |pattern|
          candidate_path = File.join(parent_dir, pattern)
          return candidate_path if File.directory?(candidate_path)
        end
        
        nil
      end

      def get_template_configuration(path)
        git_template_path = File.join(path, '.git_template')
        return nil unless File.directory?(git_template_path)
        
        begin
          Models::TemplateConfiguration.new(git_template_path)
        rescue => e
          raise TemplateValidationError.new(git_template_path, [e.message])
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
        
        case determine_development_status(analysis)
        when :folder_not_found
          recommendations << "Create the folder or check the path"
        when :not_template_project
          recommendations << "Initialize as git repository or add template configuration"
        when :application_folder_ready_for_templating
          recommendations << "Create corresponding templated folder with template configuration"
        when :template_folder_without_templated_version
          recommendations << "Create templated version for iteration and testing"
        when :templated_folder_missing_configuration
          recommendations << "Add .git_template directory to templated folder"
        when :ready_for_template_iteration
          recommendations << "Ready for template iteration and refinement"
        else
          recommendations << "Review folder structure and template configuration"
        end
        
        recommendations
      end
    end
  end
end