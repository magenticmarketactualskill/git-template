# TemplaterFolder Model
#
# This class encapsulates folder operations and analysis for template development,
# providing DRY methods for common folder checks and templated folder discovery.

require 'fileutils'

module GitTemplate
  module Models
    class TemplaterFolder
      attr_reader :path, :expanded_path

      def initialize(path)
        @path = path || '.'
        @expanded_path = File.expand_path(@path)
      end

      # Core folder checks
      def exists?
        File.directory?(@expanded_path)
      end

      def git_repository?
        return false unless exists?
        File.directory?(File.join(@expanded_path, '.git'))
      end

      def has_template_configuration?
        return false unless exists?
        File.directory?(File.join(@expanded_path, '.git_template'))
      end

      def template_configuration_path
        File.join(@expanded_path, '.git_template')
      end

      # Templated folder discovery
      def templated_folder_path
        @templated_folder_path ||= find_templated_folder_path
      end

      def templated_folder_exists?
        templated_folder_path && File.directory?(templated_folder_path)
      end

      def templated_folder
        @templated_folder ||= templated_folder_exists? ? self.class.new(templated_folder_path) : nil
      end

      # Validation methods
      def valid_application_folder?
        exists? && (git_repository? || has_template_configuration?)
      end

      def ready_for_iteration?
        valid_application_folder? && templated_folder_exists? && templated_folder&.has_template_configuration?
      end

      # Version checking methods
      def ruby_version_file
        File.join(@expanded_path, '.ruby-version')
      end

      def rails_version_file
        File.join(@expanded_path, '.rails-version')
      end

      def required_ruby_version
        return nil unless File.exist?(ruby_version_file)
        @required_ruby_version ||= File.read(ruby_version_file).strip
      end

      def required_rails_version
        return nil unless File.exist?(rails_version_file)
        @required_rails_version ||= File.read(rails_version_file).strip
      end

      def current_ruby_version
        RUBY_VERSION
      end

      def current_rails_version
        begin
          require 'rails'
          Rails::VERSION::STRING
        rescue LoadError
          nil
        end
      end

      def ruby_version_compatible?
        return true unless required_ruby_version
        Gem::Version.new(current_ruby_version) >= Gem::Version.new(required_ruby_version)
      end

      def rails_version_compatible?
        return true unless required_rails_version
        current_rails = current_rails_version
        return false unless current_rails
        Gem::Version.new(current_rails) >= Gem::Version.new(required_rails_version)
      end

      def rails_available?
        !current_rails_version.nil?
      end

      def version_check_results
        {
          ruby: {
            required: required_ruby_version,
            current: current_ruby_version,
            compatible: ruby_version_compatible?,
            file_exists: File.exist?(ruby_version_file)
          },
          rails: {
            required: required_rails_version,
            current: current_rails_version,
            compatible: rails_version_compatible?,
            available: rails_available?,
            file_exists: File.exist?(rails_version_file)
          }
        }
      end

      # Status summary
      def status_summary
        {
          path: @expanded_path,
          exists: exists?,
          is_git_repository: git_repository?,
          has_template_configuration: has_template_configuration?,
          templated_folder_path: templated_folder_path,
          templated_folder_exists: templated_folder_exists?,
          templated_has_configuration: templated_folder&.has_template_configuration? || false,
          version_check: version_check_results
        }
      end

      private

      def find_templated_folder_path
        return nil unless exists?
        
        # Convert absolute path to relative path for templated/ structure
        relative_path = calculate_relative_path
        templated_path = File.join('templated', relative_path)
        
        # Check multiple patterns for backward compatibility
        templated_patterns = build_templated_patterns(templated_path)
        
        templated_patterns.find { |candidate_path| File.directory?(candidate_path) }
      end

      def calculate_relative_path
        current_dir = Dir.pwd
        
        if @expanded_path.start_with?(current_dir)
          relative = @expanded_path[(current_dir.length + 1)..-1] # +1 to skip the '/'
          # Handle case where path is exactly the current directory
          return relative.nil? || relative.empty? ? '.' : relative
        else
          # Handle absolute paths that don't start with current dir
          return @path.start_with?('/') ? @path[1..-1] : @path
        end
      end

      def build_templated_patterns(templated_path)
        return [templated_path] if templated_path.nil? || templated_path.empty?
        
        parent_dir = File.dirname(@expanded_path)
        folder_name = File.basename(@expanded_path)
        
        patterns = [templated_path]  # New: templated/examples/rails/simple
        
        # Only add legacy patterns if we have valid parent_dir and folder_name
        if parent_dir && folder_name && !folder_name.empty?
          patterns << File.join(parent_dir, "#{folder_name}-templated")  # Legacy: simple-templated
          patterns << File.join(parent_dir, "#{folder_name}-templatd")   # Handle typo in existing examples
        end
        
        patterns
      end
    end
  end
end