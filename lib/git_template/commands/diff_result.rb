# DiffResultCommand Concern
#
# This command generates detailed file-by-file, line-by-line diff between
# source and templated folders using the FolderDiff service.

require_relative 'base'
require_relative '../services/folder_diff'
require_relative '../models/templater_folder'

module GitTemplate
  module Command
    module DiffResult
      def self.included(base)
        base.class_eval do
        desc "diff_result [PATH]", "Generate detailed file-by-file diff between source and templated folders"
        add_common_options
        option :source_folder, type: :string, desc: "Explicit source folder path"
        option :templated_folder, type: :string, desc: "Explicit templated folder path"
        option :output_file, type: :string, desc: "Custom output file path for diff results"
        
        define_method :diff_result do |path = "."|
          execute_with_error_handling("diff_result", options) do
            log_command_execution("diff_result", [path], options)
          
          measure_execution_time do
            # Validate and resolve folder paths
            source_folder, templated_folder = resolve_folder_paths(path, options)
            
            # Perform the diff operation
            diff_service = Services::FolderDiff.new(source_folder, templated_folder)
            diff_results = diff_service.perform_diff
            
            # Handle output options
            output_path = handle_output_options(diff_results, options)
            
            # Create success response
            result = create_success_response("diff_result", {
              source_folder: source_folder,
              templated_folder: templated_folder,
              output_file: output_path,
              summary: diff_results[:summary],
              total_files: diff_results[:file_diffs].length,
              differences_found: diff_results[:summary][:total_differences] > 0
            })
            
            # Output results based on format
            case options[:format]
            when "json"
              puts JSON.pretty_generate(result)
            when "summary"
              puts format_diff_summary(result)
            else
              puts format_detailed_diff_output(result, diff_results)
            end
            
            result
          end
        end
        end

        private

        define_method :resolve_folder_paths do |folder_path, options|
      # Validate the provided folder path
      expanded_folder_path = validate_directory_path(folder_path, must_exist: true)
      
      # Create TemplaterFolder to help resolve paths
      templater_folder = GitTemplate::Models::TemplaterFolder.new(expanded_folder_path)
      
      # Determine source and templated folders based on the input
      if templater_folder.has_template_configuration?
        # Input is a templated folder - find corresponding source
        source_folder = determine_source_folder(expanded_folder_path, options)
        templated_folder = expanded_folder_path
      else
        # Input is a source folder - find corresponding templated folder
        source_folder = expanded_folder_path
        templated_folder = determine_templated_folder(expanded_folder_path, options)
      end
      
      # Validate both folders exist
      validate_directory_path(source_folder, must_exist: true)
      validate_directory_path(templated_folder, must_exist: true)
      
      @logger.info("Source folder: #{source_folder}")
      @logger.info("Templated folder: #{templated_folder}")
      
      [source_folder, templated_folder]
        end

        define_method :determine_source_folder do |templated_folder_path, options|
      # If explicit source folder provided
      if options[:source_folder]
        return validate_directory_path(options[:source_folder], must_exist: true)
      end
      
      # Try to infer source folder from templated folder path
      # If templated folder is "templated/examples/rails/app", source should be "examples/rails/app"
      if templated_folder_path.include?('/templated/')
        potential_source = templated_folder_path.sub('/templated/', '/')
        return potential_source if File.directory?(potential_source)
      end
      
      # If templated folder starts with "templated/"
      if File.basename(File.dirname(templated_folder_path)) == 'templated' || 
          templated_folder_path.start_with?(File.join(Dir.pwd, 'templated'))
        relative_path = templated_folder_path.sub(/.*\/templated\//, '')
        potential_source = File.join(Dir.pwd, relative_path)
        return potential_source if File.directory?(potential_source)
      end
      
      raise StatusCommandError.new(
        "Cannot determine source folder for templated folder: #{templated_folder_path}. " \
        "Please specify --source-folder option."
      )
        end

        define_method :determine_templated_folder do |source_folder_path, options|
      # If explicit templated folder provided
      if options[:templated_folder]
        return validate_directory_path(options[:templated_folder], must_exist: true)
      end
      
      # Try to find corresponding templated folder
      templater_folder = GitTemplate::Models::TemplaterFolder.new(source_folder_path)
      
      if templater_folder.templated_folder_exists?
        return templater_folder.templated_folder_path
      end
      
      # Try common templated folder patterns
      relative_path = Pathname.new(source_folder_path).relative_path_from(Pathname.new(Dir.pwd)).to_s
      potential_templated = File.join(Dir.pwd, 'templated', relative_path)
      
      if File.directory?(potential_templated)
        return potential_templated
      end
      
      raise StatusCommandError.new(
        "Cannot determine templated folder for source folder: #{source_folder_path}. " \
        "Please specify --templated-folder option or ensure templated folder exists."
      )
        end

        define_method :handle_output_options do |diff_results, options|
      output_path = diff_results[:diff_output_path]
      
      # Handle custom output file option
      if options[:output_file]
        custom_output_path = File.expand_path(options[:output_file])
        
        # Ensure output directory exists
        ensure_directory_exists(File.dirname(custom_output_path))
        
        # Copy the diff results to custom location
        safe_file_operation do
          FileUtils.cp(output_path, custom_output_path)
        end
        
        @logger.info("Diff results copied to: #{custom_output_path}")
        output_path = custom_output_path
      end
      
      @logger.info("Diff results written to: #{output_path}")
      output_path
        end

        define_method :format_diff_summary do |result|
          summary = result[:summary]
          output = []
          
          output << "Diff Summary:"
          output << "  Source: #{result[:source_folder]}"
          output << "  Templated: #{result[:templated_folder]}"
          output << "  Total Files: #{result[:total_files]}"
          output << "  Differences Found: #{result[:differences_found] ? 'Yes' : 'No'}"
          
          if summary
            output << "  Files Added: #{summary[:files_added] || 0}"
            output << "  Files Modified: #{summary[:files_modified] || 0}"
            output << "  Files Deleted: #{summary[:files_deleted] || 0}"
          end
          
          output << "  Output File: #{result[:output_file]}" if result[:output_file]
          
          output.join("\n")
        end

        define_method :format_detailed_diff_output do |result, diff_results|
          output = []
          
          output << "=" * 80
          output << "                        Git Template Diff Results"
          output << "=" * 80
          output << ""
          output << "Source Folder: #{result[:source_folder]}"
          output << "Templated Folder: #{result[:templated_folder]}"
          output << "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          output << ""
          
          summary = result[:summary]
          if summary
            output << "SUMMARY"
            output << "-" * 40
            output << "  Total Files Compared: #{result[:total_files]}"
            output << "  Files Added: #{summary[:files_added] || 0}"
            output << "  Files Modified: #{summary[:files_modified] || 0}"
            output << "  Files Deleted: #{summary[:files_deleted] || 0}"
            output << "  Total Differences: #{summary[:total_differences] || 0}"
            output << ""
          end
          
          if result[:differences_found]
            output << "DIFFERENCES FOUND"
            output << "-" * 40
            
            if diff_results[:file_diffs] && diff_results[:file_diffs].any?
              diff_results[:file_diffs].each do |file_diff|
                next unless file_diff[:has_differences]
                
                output << "  File: #{file_diff[:relative_path]}"
                output << "    Status: #{file_diff[:status]}"
                if file_diff[:line_differences]
                  output << "    Line Differences: #{file_diff[:line_differences]}"
                end
                output << ""
              end
            end
          else
            output << "NO DIFFERENCES FOUND"
            output << "-" * 40
            output << "  Source and templated folders are identical"
            output << ""
          end
          
          output << "Detailed diff written to: #{result[:output_file]}" if result[:output_file]
          output << "=" * 80
          
          output.join("\n")
        end
      end
    end
  end
end
end