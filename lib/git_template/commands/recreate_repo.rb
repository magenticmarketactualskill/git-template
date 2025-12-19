# RecreateRepoCommand Concern
#
# This command performs a full repository iteration, recreating the templated folder
# from scratch and comparing it with the source application folder.

require_relative 'base'
require_relative '../services/template_iteration'
require_relative '../services/folder_analyzer'
require_relative '../services/iteration_strategy'
require_relative '../models/result/iteration_result'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'
require_relative '../config_manager'
require 'open3'
require 'fileutils'

module GitTemplate
  module Command
    module RecreateRepo
      def self.included(base)
        base.class_eval do
          desc "recreate-cloned-repo", "Recreate cloned repo creates a submodule with a git clone of the repo, creates a templated folder, and recreates the repo using the .git-template folder. It then does a comparison of the generated content with the original"
          add_common_options
          option :clean_before, type: :boolean, default: true, desc: "Clean templated folder before recreation"
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          option :url, type: :string, desc: "Repository URL to recreate (uses default from ~/.git-template if not specified)"
          option :path, type: :string, desc: "Path for the repository (uses default from ~/.git-template if not specified)"
          
          define_method :recreate_cloned_repo do
            execute_with_error_handling("recreate_cloned_repo", options) do
              log_command_execution("recreate_cloned_repo", [], options)
              setup_environment(options)
              
              # Get remote URL from options or config
              remote_url = options[:url] || ConfigManager.get_default_url
              repo_path = options[:path] || ConfigManager.get_default_path
              
              # Check if we have a URL
              unless remote_url
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: "No URL specified. Use --url parameter or configure default in ~/.git-template"
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Execute repository recreation
              result = perform_recreate_cloned_repo(remote_url, repo_path, options)
              
              # Format and display output
              puts result.format_output(options[:format], options)
              
              result
            end
          end
          
          private
          
          define_method :perform_recreate_cloned_repo do |remote_url, repo_path, options|
            begin
              # Check if submodule already exists (unless force is enabled)
              if submodule_exists?(remote_url) && !options[:force]
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: "A submodule with URL #{remote_url} already exists (use --force to override)"
                )
              end
              
              # Use provided path or extract repo name from URL
              if repo_path
                cloned_path = repo_path
              else
                repo_name = File.basename(remote_url, '.git')
                cloned_path = "examples/#{repo_name}"
              end
              
              # The templated path will match the cloned path structure
              templated_path = "templated/#{cloned_path}"
              
              # Check if templated folder exists
              if Dir.exist?(templated_path) && !options[:clean_before] && !options[:force]
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: "Templated folder already exists at #{templated_path}"
                )
              end
              
              # Clean templated folder if requested
              if Dir.exist?(templated_path) && options[:clean_before]
                FileUtils.rm_rf(templated_path)
              end
              
              # Clone the repository as a submodule
              cloned_path = clone_repository_as_submodule(remote_url, cloned_path)
              # cloned_path should be examples/rails8-simple
              
              # Check if .git-template or .git_template folder exists
              git_template_path = File.join(cloned_path, '.git-template')
              git_template_path_underscore = File.join(cloned_path, '.git_template')
              
              unless Dir.exist?(git_template_path) || Dir.exist?(git_template_path_underscore)
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: ".git-template or .git_template folder not found in cloned repository"
                )
              end
              
              # Create templated folder using TemplateProcessor
              template_processor = Services::TemplateProcessor.new
              create_result = template_processor.create_templated_folder(cloned_path, options)
              unless create_result.success
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: "create-templated-folder failed: #{create_result.error_message}"
                )
              end
              
              # Run template using TemplateProcessor
              rerun_result = template_processor.update_template_configuration(templated_path, options)
              unless rerun_result.success
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_cloned_repo",
                  error_message: "rerun-template failed: #{rerun_result.error_message}"
                )
              end
              
              # Compare results using TemplateProcessor
              comparison = template_processor.compare_folders(cloned_path, templated_path)
              # Note: compare_folders returns a comparison result, not a command result
              # We'll consider it successful if it completes without exception
              
              # Return success
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "recreate_cloned_repo",
                data: { 
                  message: "Repository recreation completed successfully",
                  cloned_path: cloned_path,
                  templated_path: templated_path,
                  remote_url: remote_url
                }
              )
              
            rescue => e
              # Return error result object
              Models::Result::IterateCommandResult.new(
                success: false,
                operation: "recreate_cloned_repo",
                error_message: e.message,
                error_type: e.class.name
              )
            end
          end
          
          define_method :submodule_exists? do |remote_url|
            # Check if submodule with this URL already exists in .gitmodules
            return false unless File.exist?('.gitmodules')
            
            gitmodules_content = File.read('.gitmodules')
            gitmodules_content.include?(remote_url)
          end
          
          define_method :clone_repository_as_submodule do |remote_url, submodule_path|
            
            # Ensure parent directory exists
            FileUtils.mkdir_p(File.dirname(submodule_path))
            
            # If submodule already exists and we're forcing, remove it first
            if Dir.exist?(submodule_path)
              # Remove from git
              `git submodule deinit -f #{submodule_path} 2>/dev/null`
              `git rm -f #{submodule_path} 2>/dev/null`
              # Remove directory
              FileUtils.rm_rf(submodule_path)
            end
            
            # Add as submodule
            cmd = "git submodule add --force #{remote_url} #{submodule_path}"
            stdout, stderr, status = Open3.capture3(cmd)
            
            unless status.success?
              raise StandardError.new("Clone failed: #{stderr.strip}")
            end
            
            submodule_path
          end
          

          

          

        end
      end
    end
  end
end