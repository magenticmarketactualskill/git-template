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
        # Look for folder in top-level templated/ directory structure
        # We need to work with the original relative path, not the expanded absolute path
        
        # Get the current working directory to determine relative path
        current_dir = Dir.pwd
        
        # If @path is absolute and starts with current_dir, make it relative
        if @path.start_with?(current_dir)
          relative_path = @path[(current_dir.length + 1)..-1] # +1 to skip the '/'
        else
          # If it's already relative or doesn't start with current_dir, use as-is
          relative_path = @path.start_with?('/') ? @path[1..-1] : @path
        end
        
        templated_path = File.join('templated', relative_path)
        
        # Also check legacy -templated suffix patterns for backward compatibility
        parent_dir = File.dirname(@path)
        folder_name = File.basename(@path)
        
        templated_patterns = [
          templated_path,  # New: templated/examples/rails/simple
          File.join(parent_dir, "#{folder_name}-templated"),  # Legacy: simple-templated
          File.join(parent_dir, "#{folder_name}-templatd")   # Handle typo in existing examples
        ]
        
        templated_patterns.each do |candidate_path|
          return candidate_path if File.directory?(candidate_path)
        end
        
        nil
      end
    end
  end
end