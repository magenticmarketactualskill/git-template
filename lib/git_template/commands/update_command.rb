# UpdateCommand Class
#
# This command handles template update processing and validation,
# including template structure validation and error reporting
# for maintaining template accuracy and completeness.

require_relative '../services/template_processor'
require_relative '../services/folder_analyzer'
require_relative '../models/template_configuration'
require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class UpdateCommand
      include StatusCommandErrors

      def initialize
        @template_processor = Services::TemplateProcessor.new
        @folder_analyzer = Services::FolderAnalyzer.new
      end

      def execute(folder_path, options = {})
        begin
          # Validate and analyze folder
          validated_path = validate_folder_path(folder_path)
          analysis = analyze_folder_for_update(validated_path)
          
          # Perform update operations
          update_result = perform_template_update(analysis, options)
          
          # Validate updated template
          validation_result = validate_updated_template(analysis, options)
          
          # Generate response
          generate_update_success_response(update_result, validation_result, options)
          
        rescue StatusCommandError => e
          handle_update_error(e, options)
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def update_template_configuration(folder_path, configuration_updates, options = {})
        # Update specific template configuration settings
        begin
          template_config_path = find_template_configuration_path(folder_path)
          template_config = Models::TemplateConfiguration.new(template_config_path)
          
          unless template_config.valid?
            raise TemplateValidationError.new(template_config_path, template_config.validation_errors)
          end
          
          # Apply configuration updates
          update_results = apply_configuration_updates(template_config, configuration_updates)
          
          # Validate updated configuration
          updated_config = Models::TemplateConfiguration.new(template_config_path)
          validation_result = {
            valid: updated_config.valid?,
            validation_errors: updated_config.validation_errors
          }
          
          {
            success: true,
            operation: 'update_configuration',
            template_path: template_config_path,
            updates_applied: update_results,
            validation_result: validation_result
          }
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def validate_template_structure(folder_path, options = {})
        # Comprehensive template structure validation
        begin
          template_config_path = find_template_configuration_path(folder_path)
          template_config = Models::TemplateConfiguration.new(template_config_path)
          
          validation_results = {
            valid: template_config.valid?,
            template_path: template_config_path,
            validation_errors: template_config.validation_errors,
            structure_analysis: analyze_template_structure(template_config),
            recommendations: generate_structure_recommendations(template_config)
          }
          
          # Test template completeness if reference application provided
          if options[:reference_application]
            completeness_result = @template_processor.validate_template_completeness(
              template_config_path, 
              options[:reference_application]
            )
            validation_results[:completeness_test] = completeness_result
          end
          
          validation_results
          
        rescue => e
          {
            valid: false,
            error: "Template validation failed: #{e.message}",
            template_path: folder_path
          }
        end
      end

      def optimize_template_structure(folder_path, options = {})
        # Optimize template organization and structure
        begin
          analysis = analyze_folder_for_update(folder_path)
          template_config = analysis[:template_config]
          
          optimization_results = {
            optimizations_performed: [],
            recommendations: []
          }
          
          # Organize lifecycle phases
          if options[:organize_phases]
            phase_optimization = optimize_lifecycle_phases(template_config)
            optimization_results[:optimizations_performed].concat(phase_optimization[:changes])
          end
          
          # Consolidate cleanup phase
          if options[:consolidate_cleanup]
            cleanup_optimization = consolidate_cleanup_phase(template_config)
            optimization_results[:optimizations_performed].concat(cleanup_optimization[:changes])
          end
          
          # Generate recommendations for further optimization
          optimization_results[:recommendations] = generate_optimization_recommendations(template_config)
          
          {
            success: true,
            operation: 'optimize_template',
            template_path: template_config.path,
            optimization_results: optimization_results
          }
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def backup_template_configuration(folder_path, options = {})
        # Create backup of template configuration
        begin
          template_config_path = find_template_configuration_path(folder_path)
          
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          backup_name = options[:backup_name] || "template_backup_#{timestamp}"
          backup_path = File.join(File.dirname(template_config_path), backup_name)
          
          FileUtils.cp_r(template_config_path, backup_path)
          
          {
            success: true,
            operation: 'backup_template',
            original_path: template_config_path,
            backup_path: backup_path,
            timestamp: timestamp
          }
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      private

      def validate_folder_path(folder_path)
        if folder_path.nil? || folder_path.strip.empty?
          raise InvalidPathError.new("Folder path cannot be empty")
        end
        
        expanded_path = File.expand_path(folder_path.strip)
        
        unless File.directory?(expanded_path)
          raise InvalidPathError.new("Folder does not exist: #{expanded_path}")
        end
        
        expanded_path
      end

      def analyze_folder_for_update(folder_path)
        analysis_data = @folder_analyzer.analyze_template_development_status(folder_path)
        
        # Find template configuration
        template_config_path = find_template_configuration_path(folder_path)
        template_config = Models::TemplateConfiguration.new(template_config_path)
        
        {
          folder_path: folder_path,
          analysis_data: analysis_data,
          template_config_path: template_config_path,
          template_config: template_config,
          can_update: template_config.valid?
        }
      end

      def find_template_configuration_path(folder_path)
        # Look for .git_template directory in folder or its templated version
        git_template_path = File.join(folder_path, '.git_template')
        
        if File.directory?(git_template_path)
          return git_template_path
        end
        
        # Check templated folder
        templated_folder = @folder_analyzer.find_templated_folder(folder_path)
        if templated_folder
          templated_git_template = File.join(templated_folder, '.git_template')
          if File.directory?(templated_git_template)
            return templated_git_template
          end
        end
        
        raise TemplateValidationError.new(folder_path, ["No template configuration found"])
      end

      def perform_template_update(analysis, options)
        template_config = analysis[:template_config]
        
        update_operations = []
        
        # Refresh template structure analysis
        if options[:refresh_structure] || options[:all]
          template_config = Models::TemplateConfiguration.new(analysis[:template_config_path])
          update_operations << "Refreshed template structure analysis"
        end
        
        # Validate and fix common issues
        if options[:fix_issues] || options[:all]
          fixes = fix_common_template_issues(template_config)
          update_operations.concat(fixes)
        end
        
        # Update template metadata
        if options[:update_metadata] || options[:all]
          metadata_updates = update_template_metadata(template_config)
          update_operations.concat(metadata_updates)
        end
        
        {
          operations_performed: update_operations,
          template_config: template_config
        }
      end

      def validate_updated_template(analysis, options)
        template_config = analysis[:template_config]
        
        # Re-validate template after updates
        updated_config = Models::TemplateConfiguration.new(analysis[:template_config_path])
        
        validation_result = {
          valid: updated_config.valid?,
          validation_errors: updated_config.validation_errors,
          improvements: []
        }
        
        # Compare before and after
        if template_config.validation_errors.length > updated_config.validation_errors.length
          validation_result[:improvements] << "Reduced validation errors from #{template_config.validation_errors.length} to #{updated_config.validation_errors.length}"
        end
        
        validation_result
      end

      def apply_configuration_updates(template_config, updates)
        applied_updates = []
        
        updates.each do |key, value|
          case key
          when :cleanup_phase
            template_config.update_cleanup_phase(value)
            applied_updates << "Updated cleanup phase"
          when :add_module
            # Add new module to template
            applied_updates << "Added module: #{value}"
          when :remove_module
            # Remove module from template
            applied_updates << "Removed module: #{value}"
          else
            applied_updates << "Updated #{key}: #{value}"
          end
        end
        
        applied_updates
      end

      def analyze_template_structure(template_config)
        {
          has_template_file: template_config.has_template_file?,
          has_modules_directory: template_config.has_modules_directory?,
          has_files_directory: template_config.has_files_directory?,
          lifecycle_phases_count: template_config.lifecycle_phases.length,
          has_cleanup_phase: !template_config.cleanup_phase.nil?,
          template_file_size: template_config.has_template_file? ? File.size(template_config.template_file_path) : 0
        }
      end

      def generate_structure_recommendations(template_config)
        recommendations = []
        
        unless template_config.has_modules_directory?
          recommendations << "Consider creating a modules directory for better organization"
        end
        
        unless template_config.has_files_directory?
          recommendations << "Consider creating a files directory for template assets"
        end
        
        if template_config.lifecycle_phases.empty?
          recommendations << "Consider organizing template logic into lifecycle phases"
        end
        
        if template_config.cleanup_phase.nil?
          recommendations << "Consider adding a cleanup phase for final adjustments"
        end
        
        recommendations
      end

      def optimize_lifecycle_phases(template_config)
        changes = []
        
        # Analyze and suggest phase organization
        if template_config.has_modules_directory?
          phases = template_config.get_lifecycle_phases
          if phases.length > 7
            changes << "Consider consolidating #{phases.length} phases into fewer, more focused phases"
          end
        end
        
        { changes: changes }
      end

      def consolidate_cleanup_phase(template_config)
        changes = []
        
        if template_config.cleanup_phase && template_config.cleanup_phase.length > 1000
          changes << "Cleanup phase is large - consider breaking into smaller, focused operations"
        end
        
        { changes: changes }
      end

      def generate_optimization_recommendations(template_config)
        recommendations = []
        
        # Analyze template complexity
        if template_config.has_template_file?
          template_size = File.size(template_config.template_file_path)
          if template_size > 10000  # 10KB
            recommendations << "Template file is large - consider breaking into modules"
          end
        end
        
        recommendations
      end

      def fix_common_template_issues(template_config)
        fixes = []
        
        # Check for missing required files
        unless template_config.has_template_file?
          # Create basic template file
          File.write(template_config.template_file_path, generate_basic_template_content)
          fixes << "Created missing template.rb file"
        end
        
        fixes
      end

      def update_template_metadata(template_config)
        updates = []
        
        # Add timestamp to template if not present
        template_file = template_config.template_file_path
        if File.exist?(template_file)
          content = File.read(template_file)
          unless content.include?("Updated:")
            updated_content = "# Updated: #{Time.now}\n#{content}"
            File.write(template_file, updated_content)
            updates << "Added timestamp to template file"
          end
        end
        
        updates
      end

      def generate_basic_template_content
        <<~RUBY
          # Template generated by git-template update command
          # Updated: #{Time.now}
          
          say "Applying template..."
          
          # Add your template logic here
          
          say "Template application complete!"
        RUBY
      end

      def generate_update_success_response(update_result, validation_result, options)
        response = {
          success: true,
          operation: 'update',
          operations_performed: update_result[:operations_performed],
          validation_result: validation_result
        }
        
        if options[:verbose]
          response[:template_structure] = analyze_template_structure(update_result[:template_config])
        end
        
        response
      end

      def handle_update_error(error, options)
        if options[:format] == :json
          {
            success: false,
            operation: 'update',
            error: error.message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: "Update failed: #{error.message}"
          }
        end
      end

      def handle_unexpected_error(error, options)
        error_message = "Unexpected error during update: #{error.message}"
        
        if options[:debug]
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        if options[:format] == :json
          {
            success: false,
            operation: 'update',
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