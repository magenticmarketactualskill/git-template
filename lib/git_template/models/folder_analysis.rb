# FolderAnalysis Model
#
# This class represents the analysis results of a folder, including
# its git repository status, template configuration presence, and
# related templated folder information.

require 'fileutils'
require_relative '../status_command_errors'

module GitTemplate
  module Models
    class FolderAnalysis
      include StatusCommandErrors

      attr_reader :path, :exists, :is_git_repository, :has_template_configuration,
                  :templated_folder_path, :templated_folder_exists, 
                  :templated_has_configuration, :analysis_timestamp

      def initialize(path)
        @path = File.expand_path(path)
        @analysis_timestamp = Time.now
        analyze
      end

      def status_summary
        {
          path: @path,
          exists: @exists,
          is_git_repository: @is_git_repository,
          has_template_configuration: @has_template_configuration,
          templated_folder_path: @templated_folder_path,
          templated_folder_exists: @templated_folder_exists,
          templated_has_configuration: @templated_has_configuration,
          analysis_timestamp: @analysis_timestamp
        }
      end

      def valid_application_folder?
        @exists && (@is_git_repository || @has_template_configuration)
      end

      def ready_for_iteration?
        valid_application_folder? && @templated_folder_exists && @templated_has_configuration
      end

      private

      def analyze
        begin
          @exists = File.directory?(@path)
          
          if @exists
            @is_git_repository = File.directory?(File.join(@path, '.git'))
            @has_template_configuration = File.directory?(File.join(@path, '.git_template'))
            
            # Look for corresponding templated folder
            @templated_folder_path = find_templated_folder_path
            @templated_folder_exists = @templated_folder_path && File.directory?(@templated_folder_path)
            @templated_has_configuration = @templated_folder_exists && 
                                         File.directory?(File.join(@templated_folder_path, '.git_template'))
          else
            @is_git_repository = false
            @has_template_configuration = false
            @templated_folder_path = nil
            @templated_folder_exists = false
            @templated_has_configuration = false
          end
        rescue => e
          raise FolderAnalysisError.new(@path, e.message)
        end
      end

      def find_templated_folder_path
        # Look for folder with -templated suffix in the same parent directory
        parent_dir = File.dirname(@path)
        folder_name = File.basename(@path)
        
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
    end
  end
end