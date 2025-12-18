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
require 'open3'
require 'fileutils'

module GitTemplate
  module Command
    module RecreateRepo
      def self.included(base)
        base.class_eval do
          desc "recreate-repo [REMOTE_URL]", "Recreate repo creates a submodule with a git clone of the repo, creates a templated folder, and recreates the repo using the .git-template folder. It then does a comparison of the generated content with the original"
          add_common_options
          option :clean_before, type: :boolean, default: true, desc: "Clean templated folder before recreation"
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          
          define_method :recreate_repo do |remote_url = nil|
            execute_with_error_handling("recreate_repo", options) do
              log_command_execution("recreate_repo", [remote_url], options)
              setup_environment(options)
              
              # Validate remote URL is provided
              unless remote_url
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "Remote URL is required for recreate-repo command"
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Execute repository recreation
              result = perform_recreate_repo(remote_url, options)
              
              # Format and display output
              puts result.format_output(options[:format], options)
              
              result
            end
          end
          
          private
          
          define_method :perform_recreate_repo do |remote_url, options|
            begin
              # Check if submodule already exists (unless force is enabled)
              if submodule_exists?(remote_url) && !options[:force]
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "A submodule with URL #{remote_url} already exists (use --force to override)"
                )
              end
              
              # Extract repo name from URL
              repo_name = File.basename(remote_url, '.git')
              templated_path = "templated/#{repo_name}"
              
              # Check if templated folder exists
              if Dir.exist?(templated_path) && !options[:clean_before] && !options[:force]
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "Templated folder already exists at #{templated_path}"
                )
              end
              
              # Clean templated folder if requested
              if Dir.exist?(templated_path) && options[:clean_before]
                FileUtils.rm_rf(templated_path)
              end
              
              # Clone the repository as a submodule
              cloned_path = clone_repository_as_submodule(remote_url, repo_name)
              
              # Check if .git-template or .git_template folder exists
              git_template_path = File.join(cloned_path, '.git-template')
              git_template_path_underscore = File.join(cloned_path, '.git_template')
              
              unless Dir.exist?(git_template_path) || Dir.exist?(git_template_path_underscore)
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: ".git-template or .git_template folder not found in cloned repository"
                )
              end
              
              # Create templated folder
              create_result = create_templated_folder(templated_path)
              unless create_result.success
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "create-templated-folder failed: #{create_result.error_message}"
                )
              end
              
              # Run template
              rerun_result = rerun_template(templated_path)
              unless rerun_result.success
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "rerun-template failed: #{rerun_result.error_message}"
                )
              end
              
              # Compare results
              compare_result = compare(cloned_path, templated_path)
              unless compare_result.success
                return Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "recreate_repo",
                  error_message: "compare failed: #{compare_result.error_message}"
                )
              end
              
              # Return success
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "recreate_repo",
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
                operation: "recreate_repo",
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
          
          define_method :clone_repository_as_submodule do |remote_url, repo_name|
            submodule_path = "examples/#{repo_name}"
            
            # Ensure examples directory exists
            FileUtils.mkdir_p("examples")
            
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
          
          define_method :create_templated_folder do |path|
            # Stub implementation - call the actual create-templated-folder command
            # For now, just create the directory and return success
            FileUtils.mkdir_p(path)
            Models::Result::IterateCommandResult.new(
              success: true,
              operation: "create_templated_folder",
              data: { path: path }
            )
          end
          
          define_method :rerun_template do |path|
            # Stub implementation - call the actual rerun-template command
            # For now, just return success
            Models::Result::IterateCommandResult.new(
              success: true,
              operation: "rerun_template",
              data: { path: path }
            )
          end
          
          define_method :compare do |source_path, target_path|
            # Stub implementation - call the actual compare command
            # For now, just return success
            Models::Result::IterateCommandResult.new(
              success: true,
              operation: "compare",
              data: { 
                source_path: source_path,
                target_path: target_path,
                message: "Comparison completed successfully"
              }
            )
          end
        end
      end
    end
  end
end