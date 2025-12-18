# FolderDiff Service
#
# This service performs file-by-file, line-by-line diff between two folders
# and outputs detailed diff results to a .git_template_diff file.

require 'fileutils'
require 'digest'

module GitTemplate
  module Services
    class FolderDiff
      attr_reader :source_folder, :templated_folder, :diff_output_path

      def initialize(source_folder, templated_folder)
        @source_folder = File.expand_path(source_folder)
        @templated_folder = File.expand_path(templated_folder)
        @diff_output_path = File.join(@templated_folder, '.git_template_diff')
      end

      def perform_diff
        validate_folders
        
        diff_results = {
          timestamp: Time.now,
          source_folder: @source_folder,
          templated_folder: @templated_folder,
          summary: {},
          file_diffs: []
        }

        # Get all files from both folders
        source_files = get_all_files(@source_folder)
        templated_files = get_all_files(@templated_folder)
        
        # Combine all unique file paths
        all_files = (source_files + templated_files).uniq.sort
        
        # Process each file
        all_files.each do |relative_path|
          file_diff = compare_file(relative_path, source_files, templated_files)
          diff_results[:file_diffs] << file_diff if file_diff
        end

        # Generate summary
        diff_results[:summary] = generate_summary(diff_results[:file_diffs])
        
        # Write results to file
        write_diff_results(diff_results)
        
        diff_results
      end

      private

      def validate_folders
        unless File.directory?(@source_folder)
          raise "Source folder does not exist: #{@source_folder}"
        end
        
        unless File.directory?(@templated_folder)
          raise "Templated folder does not exist: #{@templated_folder}"
        end
      end

      def get_all_files(folder_path)
        files = []
        
        Dir.glob("**/*", File::FNM_DOTMATCH, base: folder_path).each do |relative_path|
          full_path = File.join(folder_path, relative_path)
          
          # Skip directories, git internals, and special entries
          next if File.directory?(full_path)
          next if relative_path == '.' || relative_path == '..'
          next if relative_path.start_with?('.git/')
          next if relative_path == '.git_template_diff'
          
          files << relative_path
        end
        
        files.sort
      end

      def compare_file(relative_path, source_files, templated_files)
        source_path = File.join(@source_folder, relative_path)
        templated_path = File.join(@templated_folder, relative_path)
        
        source_exists = source_files.include?(relative_path)
        templated_exists = templated_files.include?(relative_path)
        
        if source_exists && templated_exists
          # Both files exist - compare content
          compare_existing_files(relative_path, source_path, templated_path)
        elsif source_exists && !templated_exists
          # File only in source
          {
            file: relative_path,
            status: 'only_in_source',
            description: "File exists only in source folder",
            source_lines: count_lines(source_path),
            templated_lines: 0,
            diff_lines: []
          }
        elsif !source_exists && templated_exists
          # File only in templated
          {
            file: relative_path,
            status: 'only_in_templated',
            description: "File exists only in templated folder",
            source_lines: 0,
            templated_lines: count_lines(templated_path),
            diff_lines: []
          }
        end
      end

      def compare_existing_files(relative_path, source_path, templated_path)
        # Read file contents
        source_content = read_file_safely(source_path)
        templated_content = read_file_safely(templated_path)
        
        # Quick check if files are identical
        if source_content == templated_content
          return {
            file: relative_path,
            status: 'identical',
            description: "Files are identical",
            source_lines: source_content.lines.count,
            templated_lines: templated_content.lines.count,
            diff_lines: []
          }
        end
        
        # Perform line-by-line diff
        diff_lines = perform_line_diff(source_content, templated_content)
        
        {
          file: relative_path,
          status: 'different',
          description: "Files have differences",
          source_lines: source_content.lines.count,
          templated_lines: templated_content.lines.count,
          diff_lines: diff_lines
        }
      end

      def perform_line_diff(source_content, templated_content)
        source_lines = source_content.lines.map(&:chomp)
        templated_lines = templated_content.lines.map(&:chomp)
        
        diff_lines = []
        max_lines = [source_lines.length, templated_lines.length].max
        
        (0...max_lines).each do |i|
          source_line = source_lines[i]
          templated_line = templated_lines[i]
          
          if source_line.nil?
            # Line only exists in templated
            diff_lines << {
              line_number: i + 1,
              type: 'added',
              source_line: nil,
              templated_line: templated_line,
              description: "Line added in templated"
            }
          elsif templated_line.nil?
            # Line only exists in source
            diff_lines << {
              line_number: i + 1,
              type: 'removed',
              source_line: source_line,
              templated_line: nil,
              description: "Line removed from templated"
            }
          elsif source_line != templated_line
            # Lines are different
            diff_lines << {
              line_number: i + 1,
              type: 'modified',
              source_line: source_line,
              templated_line: templated_line,
              description: "Line modified"
            }
          end
          # If lines are identical, we don't add them to diff_lines
        end
        
        diff_lines
      end

      def read_file_safely(file_path)
        begin
          File.read(file_path)
        rescue => e
          "[ERROR: Could not read file - #{e.message}]"
        end
      end

      def count_lines(file_path)
        begin
          File.read(file_path).lines.count
        rescue
          0
        end
      end

      def generate_summary(file_diffs)
        summary = {
          total_files: file_diffs.length,
          identical_files: 0,
          different_files: 0,
          only_in_source: 0,
          only_in_templated: 0,
          total_differences: 0
        }
        
        file_diffs.each do |diff|
          case diff[:status]
          when 'identical'
            summary[:identical_files] += 1
          when 'different'
            summary[:different_files] += 1
            summary[:total_differences] += diff[:diff_lines].length
          when 'only_in_source'
            summary[:only_in_source] += 1
            summary[:total_differences] += diff[:source_lines]
          when 'only_in_templated'
            summary[:only_in_templated] += 1
            summary[:total_differences] += diff[:templated_lines]
          end
        end
        
        summary
      end

      def write_diff_results(diff_results)
        output_content = generate_diff_report(diff_results)
        File.write(@diff_output_path, output_content)
      end

      def generate_diff_report(diff_results)
        lines = []
        
        # Header
        lines << "Git Template Folder Diff Report"
        lines << "=" * 50
        lines << "Generated: #{diff_results[:timestamp]}"
        lines << "Source Folder: #{diff_results[:source_folder]}"
        lines << "Templated Folder: #{diff_results[:templated_folder]}"
        lines << ""
        
        # Summary
        summary = diff_results[:summary]
        lines << "SUMMARY"
        lines << "-" * 20
        lines << "Total Files: #{summary[:total_files]}"
        lines << "Identical Files: #{summary[:identical_files]}"
        lines << "Different Files: #{summary[:different_files]}"
        lines << "Only in Source: #{summary[:only_in_source]}"
        lines << "Only in Templated: #{summary[:only_in_templated]}"
        lines << "Total Differences: #{summary[:total_differences]}"
        lines << ""
        
        # File-by-file details
        lines << "DETAILED DIFFERENCES"
        lines << "-" * 30
        
        diff_results[:file_diffs].each do |file_diff|
          next if file_diff[:status] == 'identical'
          
          lines << ""
          lines << "File: #{file_diff[:file]}"
          lines << "Status: #{file_diff[:status].upcase}"
          lines << "Description: #{file_diff[:description]}"
          lines << "Source Lines: #{file_diff[:source_lines]}"
          lines << "Templated Lines: #{file_diff[:templated_lines]}"
          
          if file_diff[:diff_lines].any?
            lines << ""
            lines << "Line-by-line differences:"
            
            file_diff[:diff_lines].each do |line_diff|
              lines << "  Line #{line_diff[:line_number]} (#{line_diff[:type]}):"
              
              case line_diff[:type]
              when 'added'
                lines << "    + #{line_diff[:templated_line]}"
              when 'removed'
                lines << "    - #{line_diff[:source_line]}"
              when 'modified'
                lines << "    - #{line_diff[:source_line]}"
                lines << "    + #{line_diff[:templated_line]}"
              end
            end
          end
          
          lines << "-" * 40
        end
        
        # Footer
        lines << ""
        lines << "End of Diff Report"
        lines << "Generated by git-template --compare"
        
        lines.join("\n")
      end
    end
  end
end