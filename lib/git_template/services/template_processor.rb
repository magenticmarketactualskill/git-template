# TemplateProcessor Service
#
# This service handles template application, folder comparison, and
# template completeness validation for the iterative template development process.

require 'fileutils'
require 'tmpdir'
require_relative '../models/result/comparison_result'
require_relative '../models/result/iterate_command_result'
require_relative '../models/template_configuration'
require_relative '../status_command_errors'

module GitTemplate
  module Services
    class TemplateProcessor
      include StatusCommandErrors

      def initialize
        # Service is stateless, no initialization needed
      end

      def apply_template(template_path, target_path, options = {})
        validate_template_path(template_path)
        validate_target_path(target_path)
        
        begin
          template_config = Models::TemplateConfiguration.new(template_path)
          
          unless template_config.valid?
            raise TemplateValidationError.new(template_path, template_config.validation_errors)
          end
          
          # Apply template using Rails template system
          result = execute_template_application(template_config.template_file_path, target_path, options)
          
          {
            success: true,
            template_path: template_path,
            target_path: target_path,
            applied_template: template_config.template_file_path,
            output: result[:output]
          }
        rescue => e
          if e.is_a?(TemplateValidationError) || e.is_a?(TemplateProcessingError)
            raise e
          else
            raise TemplateProcessingError.new('apply_template', e.message)
          end
        end
      end

      def compare_folders(source_path, target_path)
        begin
          Models::Result::ComparisonResult.new(source_path, target_path)
        rescue => e
          raise TemplateProcessingError.new('compare_folders', e.message)
        end
      end

      def update_cleanup_phase(template_path, differences)
        begin
          template_config = Models::TemplateConfiguration.new(template_path)
          
          unless template_config.valid?
            raise TemplateValidationError.new(template_path, template_config.validation_errors)
          end
          
          # Generate cleanup script from differences
          cleanup_script = generate_cleanup_script(differences)
          
          # Update the cleanup phase
          template_config.update_cleanup_phase(cleanup_script)
          
          {
            success: true,
            template_path: template_path,
            differences_count: differences.total_differences,
            cleanup_script: cleanup_script
          }
        rescue => e
          if e.is_a?(TemplateValidationError)
            raise e
          else
            raise TemplateProcessingError.new('update_cleanup_phase', e.message)
          end
        end
      end

      def iterate_template(application_folder, templated_folder)
        begin
          # Step 1: Clean templated folder (preserve only .git_template)
          clean_templated_folder(templated_folder)
          
          # Step 2: Apply template to generate fresh content
          template_path = File.join(templated_folder, '.git_template')
          apply_result = apply_template(template_path, templated_folder, { skip_git_init: true })
          
          # Step 3: Compare with application folder
          comparison = compare_folders(application_folder, templated_folder)
          
          # Step 4: Update cleanup phase if differences found
          if comparison.has_differences?
            update_result = update_cleanup_phase(template_path, comparison)
          end
          
          {
            success: true,
            application_folder: application_folder,
            templated_folder: templated_folder,
            template_applied: apply_result[:success],
            differences_found: comparison.has_differences?,
            differences_count: comparison.total_differences,
            cleanup_updated: comparison.has_differences?
          }
        rescue => e
          if e.is_a?(TemplateValidationError) || e.is_a?(TemplateProcessingError)
            raise e
          else
            raise TemplateProcessingError.new('iterate_template', e.message)
          end
        end
      end

      def validate_template_completeness(template_path, reference_application_path)
        begin
          # Create temporary directory for testing
          Dir.mktmpdir('template_completeness_test') do |temp_dir|
            test_app_path = File.join(temp_dir, 'test_application')
            
            # Apply template to create test application
            apply_result = apply_template(template_path, test_app_path)
            
            unless apply_result[:success]
              return {
                complete: false,
                error: 'Template application failed',
                details: apply_result
              }
            end
            
            # Compare test application with reference
            comparison = compare_folders(reference_application_path, test_app_path)
            
            {
              complete: !comparison.has_differences?,
              differences_count: comparison.total_differences,
              comparison_summary: comparison.summary,
              differences: comparison.differences
            }
          end
        rescue => e
          raise TemplateProcessingError.new('validate_template_completeness', e.message)
        end
      end

      def create_templated_folder(folder_path, options = {})
        begin
          # Logic to create templated folder structure
          # This copies the .git_template folder from the submodule to the templated subfolder
          
          templated_path = calculate_templated_path(folder_path)
          
          # Check if templated folder already exists
          if File.exist?(templated_path) && !options[:force]
            raise TemplateProcessingError.new('create_templated_folder', 
              "Templated folder already exists: #{templated_path}. Use --force to overwrite.")
          end
          
          # Create the templated folder structure
          FileUtils.mkdir_p(templated_path)
          
          # Look for .git_template directory in the source folder
          source_git_template_dir = File.join(folder_path, '.git_template')
          target_git_template_dir = File.join(templated_path, '.git_template')
          
          if File.directory?(source_git_template_dir)
            # Copy the entire .git_template directory from source to target
            FileUtils.cp_r(source_git_template_dir, templated_path)
            template_file = File.join(target_git_template_dir, 'template.rb')
            
            # Verify the template.rb file exists after copying
            unless File.exist?(template_file)
              raise TemplateProcessingError.new('create_templated_folder', 
                "No template.rb found in copied .git_template directory")
            end
          else
            # Fallback: Create .git_template directory with basic template.rb file
            FileUtils.mkdir_p(target_git_template_dir)
            template_file = File.join(target_git_template_dir, 'template.rb')
            template_content = options[:template_content] || generate_default_template_content(folder_path)
            File.write(template_file, template_content)
          end
          
          Models::Result::IterateCommandResult.new(
            success: true,
            operation: "iterate",
            data: {
              folder_path: folder_path,
              iteration_type: "create_templated_folder",
              templated_folder: templated_path,
              template_file: template_file,
              source_folder: folder_path,
              copied_from_source: File.directory?(source_git_template_dir)
            }
          )
        rescue => e
          Models::Result::IterateCommandResult.new(
            success: false,
            operation: "iterate",
            error_message: "Templated folder creation failed: #{e.message}"
          )
        end
      end

      def update_template_configuration(folder_path, options = {})
        begin
          # Logic to update template configuration
          # This would typically involve updating the template.rb file
          # based on current folder state
          
          template_config_path = File.join(folder_path, '.git_template')
          
          unless File.directory?(template_config_path)
            raise TemplateProcessingError.new('update_template_configuration', 
              "No template configuration found at #{template_config_path}")
          end
          
          template_file = File.join(template_config_path, 'template.rb')
          
          # Update template configuration (placeholder logic)
          updated_content = generate_updated_template_content(folder_path)
          File.write(template_file, updated_content)
          
          Models::Result::IterateCommandResult.new(
            success: true,
            operation: "iterate",
            data: {
              folder_path: folder_path,
              iteration_type: "template_iteration",
              template_file: template_file,
              updated_at: Time.now
            }
          )
        rescue => e
          Models::Result::IterateCommandResult.new(
            success: false,
            operation: "iterate",
            error_message: "Template update failed: #{e.message}"
          )
        end
      end

      private

      def validate_template_path(template_path)
        unless File.directory?(template_path)
          raise InvalidPathError.new(template_path)
        end
        
        template_file = File.join(template_path, 'template.rb')
        unless File.exist?(template_file)
          raise TemplateValidationError.new(template_path, ['Missing template.rb file'])
        end
      end

      def validate_target_path(target_path)
        parent_dir = File.dirname(target_path)
        unless File.directory?(parent_dir)
          raise InvalidPathError.new("Parent directory does not exist: #{parent_dir}")
        end
      end

      def execute_template_application(template_file, target_path, options)
        # Ensure target directory exists
        FileUtils.mkdir_p(target_path)
        
        # Change to target directory and apply template
        Dir.chdir(target_path) do
          # Check if it's a Rails application or create minimal structure
          unless File.exist?('config/application.rb') || options[:skip_rails_check]
            create_minimal_rails_structure
          end
          
          # Apply the template
          if File.exist?('bin/rails')
            # Use Rails template system
            cmd = "bin/rails app:template LOCATION=#{template_file}"
            output = `#{cmd} 2>&1`
            success = $?.success?
          else
            # Execute template directly (for non-Rails templates)
            output = execute_template_directly(template_file)
            success = true
          end
          
          {
            success: success,
            output: output,
            command: cmd || 'direct_execution'
          }
        end
      end

      def create_minimal_rails_structure
        # Create minimal Rails directory structure for template application
        %w[app bin config db lib public].each do |dir|
          FileUtils.mkdir_p(dir)
        end
        
        # Create minimal files
        File.write('config/application.rb', minimal_application_rb_content)
        File.write('bin/rails', minimal_rails_script_content)
        FileUtils.chmod(0755, 'bin/rails')
        File.write('Gemfile', minimal_gemfile_content)
      end

      def execute_template_directly(template_file)
        # For non-Rails templates, execute Ruby code directly
        # This is a simplified approach - in practice, you might want more sophisticated handling
        begin
          template_content = File.read(template_file)
          eval(template_content)
          "Template executed directly"
        rescue => e
          "Template execution failed: #{e.message}"
        end
      end

      def clean_templated_folder(templated_folder)
        return unless File.directory?(templated_folder)
        
        # Preserve .git_template directory
        git_template_path = File.join(templated_folder, '.git_template')
        temp_git_template = nil
        
        if File.directory?(git_template_path)
          # Move .git_template to temporary location
          temp_git_template = File.join(Dir.tmpdir, "git_template_backup_#{Time.now.to_i}")
          FileUtils.mv(git_template_path, temp_git_template)
        end
        
        begin
          # Remove all contents
          Dir.entries(templated_folder).each do |entry|
            next if entry == '.' || entry == '..'
            entry_path = File.join(templated_folder, entry)
            FileUtils.rm_rf(entry_path)
          end
          
          # Restore .git_template if it existed
          if temp_git_template && File.directory?(temp_git_template)
            FileUtils.mv(temp_git_template, git_template_path)
          end
        rescue => e
          # Restore .git_template on error
          if temp_git_template && File.directory?(temp_git_template)
            FileUtils.mv(temp_git_template, git_template_path) rescue nil
          end
          raise e
        end
      end

      def generate_cleanup_script(comparison_result)
        script_lines = [
          "# Cleanup phase - generated by template iteration",
          "# Generated at: #{Time.now}",
          "# Differences found: #{comparison_result.total_differences}",
          ""
        ]
        
        script_lines << comparison_result.generate_diff_script
        script_lines.join("\n")
      end

      def minimal_application_rb_content
        <<~RUBY
          # Minimal Rails application configuration for template processing
          require_relative "boot"
          require "rails/all"
          
          module TemplateTestApp
            class Application < Rails::Application
              config.load_defaults 7.0
            end
          end
        RUBY
      end

      def minimal_rails_script_content
        <<~RUBY
          #!/usr/bin/env ruby
          # Minimal Rails script for template processing
          APP_PATH = File.expand_path("../config/application", __dir__)
          require_relative "../config/boot"
          require "rails/commands"
        RUBY
      end

      def minimal_gemfile_content
        <<~RUBY
          source "https://rubygems.org"
          git_source(:github) { |repo| "https://github.com/\#{repo}.git" }
          
          ruby "3.2.0"
          
          gem "rails", "~> 7.0.0"
        RUBY
      end

      def calculate_templated_path(source_path)
        current_dir = Dir.pwd
        expanded_path = File.expand_path(source_path)
        
        # If expanded_path is absolute and starts with current_dir, make it relative
        if expanded_path.start_with?(current_dir)
          relative_path = expanded_path[(current_dir.length + 1)..-1] # +1 to skip the '/'
        else
          # If it's already relative or doesn't start with current_dir, use basename
          relative_path = source_path.start_with?('/') ? File.basename(source_path) : source_path
        end
        
        File.join('templated', relative_path)
      end

      def generate_default_template_content(source_path)
        folder_name = File.basename(source_path)
        
        <<~RUBY
          # Template for #{folder_name}
          # Generated by git-template
          # Created: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
          
          say "Applying #{folder_name} template..."
          
          # Add your template logic here
          # Examples:
          # gem 'some_gem'
          # generate 'controller', 'welcome'
          # route "root 'welcome#index'"
          # 
          # File operations:
          # copy_file 'config/database.yml.example', 'config/database.yml'
          # template 'app/models/user.rb.tt', 'app/models/user.rb'
          # 
          # Directory operations:
          # empty_directory 'app/assets/stylesheets'
          # 
          # Git operations:
          # git :init
          # git add: '.'
          # git commit: '-m "Initial commit"'
          
          say "#{folder_name} template application complete!"
        RUBY
      end

      def generate_updated_template_content(folder_path)
        folder_name = File.basename(folder_path)
        
        <<~RUBY
          # Template for #{folder_name}
          # Updated by git-template
          # Updated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}
          
          say "Applying updated #{folder_name} template..."
          
          # Template logic updated based on current folder state
          # Add your updated template logic here
          
          say "#{folder_name} template update complete!"
        RUBY
      end
    end
  end
end