# IterateCommand Class
#
# This command handles template iteration with configuration preservation,
# template application and comparison functionality, integrating with
# TemplateProcessor service for the iterative template development process.

require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class IterateCommand
      include StatusCommandErrors

      def initialize
        @template_processor = Services::TemplateProcessor.new
        @folder_analyzer = Services::FolderAnalyzer.new
      end

      def execute(folder_path, options = {})
        begin
          # Validate and analyze folder
          validated_path = validate_folder_path(folder_path)
          analysis = analyze_folder_for_iteration(validated_path)
          
          # Determine iteration strategy
          iteration_strategy = determine_iteration_strategy(analysis, options)
          
          # Execute iteration based on strategy
          case iteration_strategy[:type]
          when :full_iteration
            execute_full_iteration(analysis, options)
          when :create_templated_folder
            execute_create_templated_folder(analysis, options)
          when :template_only_update
            execute_template_only_update(analysis, options)
          else
            raise TemplateProcessingError.new('iterate', "Cannot iterate: #{iteration_strategy[:reason]}")
          end
          
        rescue StatusCommandError => e
          handle_iterate_error(e, options)
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def iterate_with_comparison(application_folder, templated_folder, options = {})
        # Perform full iteration with detailed comparison reporting
        begin
          # Validate both folders
          validate_iteration_folders(application_folder, templated_folder)
          
          # Perform iteration
          result = @template_processor.iterate_template(application_folder, templated_folder)
          
          # Generate detailed comparison if requested
          if options[:detailed_comparison]
            comparison = @template_processor.compare_folders(application_folder, templated_folder)
            result[:detailed_comparison] = {
              summary: comparison.summary,
              differences: comparison.differences,
              diff_script: comparison.generate_diff_script
            }
          end
          
          generate_iteration_success_response(result, options)
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def validate_iteration_setup(folder_path)
        # Validate that folder is ready for iteration
        begin
          analysis = @folder_analyzer.analyze_template_development_status(folder_path)
          
          validation_results = {
            ready_for_iteration: false,
            issues: [],
            recommendations: []
          }
          
          folder_analysis = analysis[:folder_analysis]
          
          # Check basic requirements
          unless folder_analysis[:exists]
            validation_results[:issues] << "Folder does not exist"
            validation_results[:recommendations] << "Create the folder or check the path"
            return validation_results
          end
          
          # Check for application folder requirements
          unless folder_analysis[:is_git_repository] || folder_analysis[:has_template_configuration]
            validation_results[:issues] << "Folder is not a git repository and has no template configuration"
            validation_results[:recommendations] << "Initialize as git repository or add template configuration"
          end
          
          # Check templated folder status
          if folder_analysis[:templated_folder_exists]
            unless folder_analysis[:templated_has_configuration]
              validation_results[:issues] << "Templated folder exists but lacks template configuration"
              validation_results[:recommendations] << "Add .git_template directory to templated folder"
            end
          else
            validation_results[:recommendations] << "Create templated folder for iteration testing"
          end
          
          # Check template configuration validity
          if analysis[:template_configuration]
            template_config = analysis[:template_configuration]
            unless template_config[:valid]
              validation_results[:issues] << "Template configuration is invalid"
              validation_results[:issues].concat(template_config[:validation_errors])
              validation_results[:recommendations] << "Fix template configuration errors"
            end
          end
          
          validation_results[:ready_for_iteration] = validation_results[:issues].empty?
          validation_results
          
        rescue => e
          {
            ready_for_iteration: false,
            issues: ["Failed to validate iteration setup: #{e.message}"],
            recommendations: ["Review folder structure and fix any issues"]
          }
        end
      end

      def preview_iteration_changes(folder_path, options = {})
        # Preview what changes would be made during iteration without actually performing them
        begin
          analysis = analyze_folder_for_iteration(folder_path)
          
          unless analysis[:can_iterate]
            return {
              success: false,
              error: "Cannot preview iteration: #{analysis[:reason]}"
            }
          end
          
          application_folder = analysis[:application_folder]
          templated_folder = analysis[:templated_folder]
          
          # Create temporary copy for preview
          Dir.mktmpdir('iterate_preview') do |temp_dir|
            temp_templated = File.join(temp_dir, 'templated_preview')
            FileUtils.cp_r(templated_folder, temp_templated)
            
            # Perform iteration on temporary copy
            preview_result = @template_processor.iterate_template(application_folder, temp_templated)
            
            # Compare to show what would change
            comparison = @template_processor.compare_folders(application_folder, temp_templated)
            
            {
              success: true,
              preview: true,
              would_apply_template: preview_result[:template_applied],
              would_find_differences: preview_result[:differences_found],
              differences_count: preview_result[:differences_count],
              would_update_cleanup: preview_result[:cleanup_updated],
              comparison_summary: comparison.summary,
              differences: comparison.differences
            }
          end
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      private

      def validate_folder_path(folder_path)
        if folder_path.nil? || folder_path.strip.empty?
          raise InvalidPathError.new("Folder path cannot be empty")
        end
        
        File.expand_path(folder_path.strip)
      end

      def analyze_folder_for_iteration(folder_path)
        analysis_data = @folder_analyzer.analyze_template_development_status(folder_path)
        folder_analysis = analysis_data[:folder_analysis]
        
        analysis = {
          application_folder: folder_path,
          templated_folder: folder_analysis[:templated_folder_path],
          can_iterate: false,
          reason: nil
        }
        
        # Determine if iteration is possible
        case analysis_data[:development_status]
        when :ready_for_template_iteration
          analysis[:can_iterate] = true
          analysis[:reason] = "Ready for iteration"
        when :application_folder_ready_for_templating
          analysis[:can_iterate] = false
          analysis[:reason] = "No templated folder exists - create one first"
        when :templated_folder_missing_configuration
          analysis[:can_iterate] = false
          analysis[:reason] = "Templated folder lacks template configuration"
        when :template_folder_without_templated_version
          analysis[:can_iterate] = false
          analysis[:reason] = "No templated version exists for testing"
        else
          analysis[:can_iterate] = false
          analysis[:reason] = "Folder is not properly set up for template iteration"
        end
        
        analysis[:analysis_data] = analysis_data
        analysis
      end

      def determine_iteration_strategy(analysis, options)
        if analysis[:can_iterate]
          { type: :full_iteration, reason: "Ready for full iteration" }
        elsif analysis[:templated_folder] && File.directory?(analysis[:templated_folder])
          { type: :template_only_update, reason: "Update existing templated folder" }
        elsif options[:create_templated_folder]
          { type: :create_templated_folder, reason: "Create new templated folder" }
        else
          { type: :cannot_iterate, reason: analysis[:reason] }
        end
      end

      def execute_full_iteration(analysis, options)
        application_folder = analysis[:application_folder]
        templated_folder = analysis[:templated_folder]
        
        result = @template_processor.iterate_template(application_folder, templated_folder)
        
        generate_iteration_success_response(result, options)
      end

      def execute_create_templated_folder(analysis, options)
        application_folder = analysis[:application_folder]
        # Use new templated/ directory structure
        # We need to work with relative paths for the templated/ structure
        
        # Get the current working directory to determine relative path
        current_dir = Dir.pwd
        expanded_path = File.expand_path(application_folder)
        
        # If expanded_path is absolute and starts with current_dir, make it relative
        if expanded_path.start_with?(current_dir)
          relative_path = expanded_path[(current_dir.length + 1)..-1] # +1 to skip the '/'
        else
          # If it's already relative or doesn't start with current_dir, use as-is
          relative_path = application_folder.start_with?('/') ? application_folder[1..-1] : application_folder
        end
        
        templated_folder = File.join('templated', relative_path)
        
        # Create templated folder structure
        FileUtils.mkdir_p(templated_folder)
        
        # Create basic template configuration
        git_template_dir = File.join(templated_folder, '.git_template')
        FileUtils.mkdir_p(git_template_dir)
        
        # Create basic template.rb
        template_file = File.join(git_template_dir, 'template.rb')
        File.write(template_file, generate_basic_template_content)
        
        # Now perform iteration
        result = @template_processor.iterate_template(application_folder, templated_folder)
        result[:created_templated_folder] = true
        result[:templated_folder_path] = templated_folder
        
        generate_iteration_success_response(result, options)
      end

      def execute_template_only_update(analysis, options)
        templated_folder = analysis[:templated_folder]
        template_path = File.join(templated_folder, '.git_template')
        
        # Apply template to update templated folder
        result = @template_processor.apply_template(template_path, templated_folder)
        
        {
          success: true,
          operation: 'template_update',
          templated_folder: templated_folder,
          template_applied: result[:success]
        }
      end

      def validate_iteration_folders(application_folder, templated_folder)
        unless File.directory?(application_folder)
          raise InvalidPathError.new("Application folder does not exist: #{application_folder}")
        end
        
        unless File.directory?(templated_folder)
          raise InvalidPathError.new("Templated folder does not exist: #{templated_folder}")
        end
        
        template_config_path = File.join(templated_folder, '.git_template')
        unless File.directory?(template_config_path)
          raise TemplateValidationError.new(template_config_path, ["Template configuration directory missing"])
        end
      end

      def generate_basic_template_content
        <<~RUBY
          # Template generated by git-template iterate command
          # Add your template logic here
          
          say "Applying template..."
          
          # Example template operations:
          # gem 'some_gem'
          # generate 'controller', 'welcome'
          # route "root 'welcome#index'"
          
          say "Template application complete!"
        RUBY
      end

      def generate_iteration_success_response(result, options)
        response = {
          success: true,
          operation: 'iterate',
          application_folder: result[:application_folder],
          templated_folder: result[:templated_folder],
          template_applied: result[:template_applied],
          differences_found: result[:differences_found],
          differences_count: result[:differences_count],
          cleanup_updated: result[:cleanup_updated]
        }
        
        if options[:verbose] && result[:detailed_comparison]
          response[:detailed_comparison] = result[:detailed_comparison]
        end
        
        if result[:created_templated_folder]
          response[:created_templated_folder] = true
          response[:templated_folder_path] = result[:templated_folder_path]
        end
        
        response
      end

      def handle_iterate_error(error, options)
        if options[:format] == :json
          {
            success: false,
            operation: 'iterate',
            error: error.message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: "Iteration failed: #{error.message}"
          }
        end
      end

      def handle_unexpected_error(error, options)
        error_message = "Unexpected error during iteration: #{error.message}"
        
        if options[:debug]
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        if options[:format] == :json
          {
            success: false,
            operation: 'iterate',
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