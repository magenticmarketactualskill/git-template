# CloneCommand Concern
#
# This command handles git repository cloning for template development,
# including URL validation, error handling for invalid URLs and existing directories,
# and integration with GitOperations service.

require_relative 'base'
require_relative '../services/git_operations'

module GitTemplate
  module Command
    module Clone
      def self.included(base)
        base.class_eval do
        desc "clone GIT_URL [TARGET_FOLDER]", "Clone a git repository for template development"
        add_common_options
        option :quiet, type: :boolean, desc: "Suppress output during clone"
        option :depth, type: :numeric, desc: "Create a shallow clone with specified depth"
        option :branch, type: :string, desc: "Clone specific branch"
        option :allow_existing, type: :boolean, desc: "Allow cloning into existing directory"
        option :create_template_config, type: :boolean, desc: "Create basic template configuration"
        option :create_readme, type: :boolean, desc: "Create template development README"
        
        define_method :clone do |git_url, target_folder = nil|
          execute_with_error_handling("clone", options) do
            log_command_execution("clone", [git_url, target_folder], options)
            
            measure_execution_time do
              # Validate and prepare parameters
              validated_url = validate_git_url(git_url)
              target_path = determine_target_path(git_url, target_folder)
              
              # Validate target path
              validate_target_path(target_path, options)
              
              # Perform clone operation
              clone_options = prepare_clone_options(options)
              git_operations = Services::GitOperations.new
              result = git_operations.clone_repository(validated_url, target_path, clone_options)
              
              # Generate success response
              create_success_response("clone", {
                git_url: validated_url,
                target_path: target_path,
                repository_name: extract_repository_name(git_url),
                clone_result: result
              })
            end
          end
        end

        private

        define_method :validate_git_url do |url|
          if url.nil? || url.strip.empty?
            raise GitOperationError.new('clone', 'Git URL cannot be empty')
          end
          
          url = url.strip
          
          # Basic URL validation - delegate detailed validation to GitOperations
          # This is just a preliminary check
          unless url.match?(/^(https?:\/\/|git@|ssh:\/\/)/) || url.include?('.git')
            raise GitOperationError.new('clone', "Invalid git URL format: #{url}")
          end
          
          url
        end

        define_method :determine_target_path do |git_url, target_folder|
          if target_folder
            File.expand_path(target_folder)
          else
            # Extract repository name from URL
            repo_name = extract_repository_name(git_url)
            File.expand_path(repo_name)
          end
        end

        define_method :extract_repository_name do |git_url|
          # Extract repository name from various git URL formats
          if git_url.match(/\/([^\/]+)\.git$/)
            $1
          elsif git_url.match(/\/([^\/]+)\/?$/)
            $1
          elsif git_url.match(/:([^\/]+)\.git$/)
            $1
          else
            # Fallback to a generic name
            "cloned_repository_#{Time.now.to_i}"
          end
        end

        define_method :validate_target_path do |target_path, options|
          # Check if target already exists
          if File.exist?(target_path) && !options[:allow_existing]
            if File.directory?(target_path)
              unless Dir.empty?(target_path)
                raise GitOperationError.new('clone', "Target directory exists and is not empty: #{target_path}")
              end
            else
              raise GitOperationError.new('clone', "Target path exists and is not a directory: #{target_path}")
            end
          end
          
          # Check parent directory
          parent_dir = File.dirname(target_path)
          unless File.directory?(parent_dir)
            raise InvalidPathError.new("Parent directory does not exist: #{parent_dir}")
          end
        end

        define_method :prepare_clone_options do |options|
          clone_options = {}
          
          clone_options[:quiet] = options[:quiet] if options.key?(:quiet)
          clone_options[:depth] = options[:depth] if options[:depth]
          clone_options[:branch] = options[:branch] if options[:branch]
          clone_options[:allow_existing] = options[:allow_existing] if options.key?(:allow_existing)
          
          clone_options
        end
      end
    end
  end
end
end
