# TemplateConfiguration Model
#
# This class represents a template configuration found in a .git_template directory,
# providing methods for loading, validating, and managing template structure.

require 'yaml'
require_relative '../status_command_errors'

module GitTemplate
  module Models
    class TemplateConfiguration
      include StatusCommandErrors

      attr_reader :path, :template_file, :modules_directory, :files_directory,
                  :lifecycle_phases, :cleanup_phase, :validation_errors

      def initialize(git_template_path)
        @path = File.expand_path(git_template_path)
        @validation_errors = []
        load_configuration
      end

      def valid?
        @validation_errors.empty?
      end

      def template_file_path
        File.join(@path, 'template.rb')
      end

      def modules_directory_path
        File.join(@path, 'modules')
      end

      def files_directory_path
        File.join(@path, 'files')
      end

      def has_template_file?
        File.exist?(template_file_path)
      end

      def has_modules_directory?
        File.directory?(modules_directory_path)
      end

      def has_files_directory?
        File.directory?(files_directory_path)
      end

      def get_lifecycle_phases
        return [] unless has_modules_directory?
        
        Dir.entries(modules_directory_path)
           .select { |entry| File.directory?(File.join(modules_directory_path, entry)) }
           .reject { |entry| entry.start_with?('.') }
           .sort
      end

      def get_cleanup_phase_content
        cleanup_file = File.join(@path, 'cleanup.rb')
        return nil unless File.exist?(cleanup_file)
        
        File.read(cleanup_file)
      end

      def update_cleanup_phase(additional_content)
        cleanup_file = File.join(@path, 'cleanup.rb')
        
        existing_content = get_cleanup_phase_content || ""
        updated_content = existing_content + "\n\n# Added by template iteration\n" + additional_content
        
        File.write(cleanup_file, updated_content)
      end

      private

      def load_configuration
        unless File.directory?(@path)
          @validation_errors << "Template configuration directory does not exist: #{@path}"
          return
        end

        validate_required_files
        load_template_structure
      end

      def validate_required_files
        unless has_template_file?
          @validation_errors << "Missing required template.rb file"
        end

        # Check if template.rb is valid Ruby syntax
        if has_template_file?
          begin
            File.read(template_file_path)
            # Basic syntax check - could be enhanced with actual Ruby parsing
          rescue => e
            @validation_errors << "Template file is not readable: #{e.message}"
          end
        end
      end

      def load_template_structure
        @template_file = template_file_path if has_template_file?
        @modules_directory = modules_directory_path if has_modules_directory?
        @files_directory = files_directory_path if has_files_directory?
        @lifecycle_phases = get_lifecycle_phases
        @cleanup_phase = get_cleanup_phase_content
      end
    end
  end
end