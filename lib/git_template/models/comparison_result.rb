# ComparisonResult Model
#
# This class represents the result of comparing two folder structures,
# identifying added, modified, and deleted files and directories.

require 'fileutils'
require 'digest'
require_relative '../status_command_errors'

module GitTemplate
  module Models
    class ComparisonResult
      include StatusCommandErrors

      attr_reader :source_path, :target_path, :added_files, :modified_files, 
                  :deleted_files, :differences, :comparison_timestamp

      def initialize(source_path, target_path)
        @source_path = File.expand_path(source_path)
        @target_path = File.expand_path(target_path)
        @comparison_timestamp = Time.now
        @added_files = []
        @modified_files = []
        @deleted_files = []
        @differences = []
        
        perform_comparison
      end

      def has_differences?
        !(@added_files.empty? && @modified_files.empty? && @deleted_files.empty?)
      end

      def total_differences
        @added_files.length + @modified_files.length + @deleted_files.length
      end

      def summary
        {
          source_path: @source_path,
          target_path: @target_path,
          added_files: @added_files.length,
          modified_files: @modified_files.length,
          deleted_files: @deleted_files.length,
          total_differences: total_differences,
          has_differences: has_differences?,
          comparison_timestamp: @comparison_timestamp
        }
      end

      def generate_diff_script
        script_lines = []
        
        @added_files.each do |file|
          script_lines << "# Add file: #{file}"
          script_lines << "copy_file '#{File.join(@source_path, file)}', '#{file}'"
        end
        
        @modified_files.each do |file|
          script_lines << "# Modify file: #{file}"
          script_lines << "copy_file '#{File.join(@source_path, file)}', '#{file}', force: true"
        end
        
        @deleted_files.each do |file|
          script_lines << "# Remove file: #{file}"
          script_lines << "remove_file '#{file}'"
        end
        
        script_lines.join("\n")
      end

      private

      def perform_comparison
        unless File.directory?(@source_path) && File.directory?(@target_path)
          raise FolderAnalysisError.new("#{@source_path} or #{@target_path}", "One or both paths are not directories")
        end

        source_files = get_file_list(@source_path)
        target_files = get_file_list(@target_path)

        # Find added files (in source but not in target)
        @added_files = source_files.keys - target_files.keys

        # Find deleted files (in target but not in source)
        @deleted_files = target_files.keys - source_files.keys

        # Find modified files (in both but with different content)
        common_files = source_files.keys & target_files.keys
        @modified_files = common_files.select do |file|
          source_files[file] != target_files[file]
        end

        # Generate detailed differences
        @differences = generate_detailed_differences(source_files, target_files)
      end

      def get_file_list(directory_path)
        files = {}
        
        Dir.glob("**/*", File::FNM_DOTMATCH, base: directory_path).each do |relative_path|
          full_path = File.join(directory_path, relative_path)
          
          # Skip directories and special entries
          next if File.directory?(full_path)
          next if relative_path == '.' || relative_path == '..'
          next if relative_path.start_with?('.git/')  # Skip git internals
          
          # Calculate file hash for content comparison
          begin
            files[relative_path] = Digest::MD5.hexdigest(File.read(full_path))
          rescue => e
            # If we can't read the file, use a placeholder hash
            files[relative_path] = "unreadable:#{e.message}"
          end
        end
        
        files
      end

      def generate_detailed_differences(source_files, target_files)
        diffs = []
        
        @added_files.each do |file|
          diffs << {
            type: :added,
            file: file,
            description: "File added in source: #{file}"
          }
        end
        
        @deleted_files.each do |file|
          diffs << {
            type: :deleted,
            file: file,
            description: "File deleted from source: #{file}"
          }
        end
        
        @modified_files.each do |file|
          diffs << {
            type: :modified,
            file: file,
            description: "File modified: #{file}",
            source_hash: source_files[file],
            target_hash: target_files[file]
          }
        end
        
        diffs
      end
    end
  end
end