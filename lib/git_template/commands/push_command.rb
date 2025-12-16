# PushCommand Class
#
# This command handles git repository pushing with initialization,
# repository verification and error handling, integrating with
# GitOperations service for template development workflow.

require_relative '../services/git_operations'
require_relative '../services/folder_analyzer'
require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class PushCommand
      include StatusCommandErrors

      def initialize
        @git_operations = Services::GitOperations.new
        @folder_analyzer = Services::FolderAnalyzer.new
      end

      def execute(folder_path, remote_url = nil, options = {})
        begin
          # Validate and prepare parameters
          validated_path = validate_folder_path(folder_path)
          
          # Analyze folder and verify git repository status
          repository_status = verify_repository_status(validated_path, options)
          
          # Initialize repository if needed
          if !repository_status[:is_git_repository] && options[:initialize_if_needed]
            init_result = @git_operations.initialize_repository(validated_path)
            repository_status[:initialized] = init_result[:success]
          end
          
          # Prepare push options
          push_options = prepare_push_options(options, remote_url)
          
          # Perform push operation
          push_result = @git_operations.push_to_remote(validated_path, remote_url, push_options)
          
          # Generate success response
          generate_push_success_response(push_result, repository_status, options)
          
        rescue StatusCommandError => e
          handle_push_error(e, options)
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def push_template_development(folder_path, options = {})
        # Push template development work with specific workflow considerations
        begin
          # Analyze template development status
          analysis = @folder_analyzer.analyze_template_development_status(folder_path)
          
          # Validate that folder is ready for pushing
          validation_result = validate_template_development_push(analysis, options)
          unless validation_result[:ready_for_push]
            return {
              success: false,
              error: "Not ready for push: #{validation_result[:issues].join(', ')}",
              recommendations: validation_result[:recommendations]
            }
          end
          
          # Prepare template-specific push options
          template_push_options = prepare_template_push_options(analysis, options)
          
          # Execute push with template development considerations
          push_result = execute(folder_path, options[:remote_url], template_push_options)
          
          # Add template development context to response
          if push_result[:success]
            push_result[:template_development_context] = {
              development_status: analysis[:development_status],
              has_template_configuration: analysis.dig(:folder_analysis, :has_template_configuration),
              templated_folder_exists: analysis.dig(:folder_analysis, :templated_folder_exists)
            }
          end
          
          push_result
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def verify_push_readiness(folder_path, options = {})
        # Verify that folder is ready for push operations
        begin
          validated_path = validate_folder_path(folder_path)
          
          readiness_check = {
            ready_for_push: false,
            issues: [],
            warnings: [],
            recommendations: []
          }
          
          # Check if folder exists
          unless File.directory?(validated_path)
            readiness_check[:issues] << "Folder does not exist"
            return readiness_check
          end
          
          # Check git repository status
          repository_status = @git_operations.get_repository_status(validated_path)
          
          unless repository_status[:is_git_repository]
            if options[:initialize_if_needed]
              readiness_check[:warnings] << "Not a git repository - will be initialized"
            else
              readiness_check[:issues] << "Not a git repository"
              readiness_check[:recommendations] << "Initialize as git repository or use --initialize-if-needed option"
            end
          else
            # Check for uncommitted changes
            if repository_status[:has_changes]
              if options[:commit_changes]
                readiness_check[:warnings] << "Has uncommitted changes - will be committed"
              else
                readiness_check[:issues] << "Has uncommitted changes"
                readiness_check[:recommendations] << "Commit changes or use --commit-changes option"
              end
            end
            
            # Check for remote configuration
            if repository_status[:remotes].empty? && !options[:remote_url]
              readiness_check[:issues] << "No remote repository configured"
              readiness_check[:recommendations] << "Configure remote repository or provide remote URL"
            end
          end
          
          readiness_check[:ready_for_push] = readiness_check[:issues].empty?
          readiness_check
          
        rescue => e
          {
            ready_for_push: false,
            issues: ["Failed to verify push readiness: #{e.message}"],
            warnings: [],
            recommendations: ["Review folder and git configuration"]
          }
        end
      end

      def setup_remote_repository(folder_path, remote_url, options = {})
        # Set up remote repository configuration
        begin
          validated_path = validate_folder_path(folder_path)
          
          # Verify it's a git repository
          unless @git_operations.is_git_repository?(validated_path)
            if options[:initialize_if_needed]
              init_result = @git_operations.initialize_repository(validated_path)
              unless init_result[:success]
                raise GitOperationError.new('setup_remote', 'Failed to initialize repository')
              end
            else
              raise GitOperationError.new('setup_remote', 'Not a git repository')
            end
          end
          
          # Set up remote
          Dir.chdir(validated_path) do
            remote_name = options[:remote_name] || 'origin'
            
            # Check if remote already exists
            stdout, stderr, status = Open3.capture3("git remote get-url #{remote_name}")
            
            if status.success?
              # Remote exists, update if different
              existing_url = stdout.strip
              if existing_url != remote_url
                stdout, stderr, status = Open3.capture3("git remote set-url #{remote_name} #{remote_url}")
                unless status.success?
                  raise GitOperationError.new('remote set-url', stderr.strip)
                end
                operation = 'updated_remote'
              else
                operation = 'remote_already_configured'
              end
            else
              # Remote doesn't exist, add it
              stdout, stderr, status = Open3.capture3("git remote add #{remote_name} #{remote_url}")
              unless status.success?
                raise GitOperationError.new('remote add', stderr.strip)
              end
              operation = 'added_remote'
            end
          end
          
          {
            success: true,
            operation: operation,
            folder_path: validated_path,
            remote_url: remote_url,
            remote_name: options[:remote_name] || 'origin'
          }
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def push_with_backup(folder_path, remote_url = nil, options = {})
        # Push with automatic backup creation
        begin
          # Create backup before pushing
          backup_result = create_push_backup(folder_path, options)
          
          # Perform push
          push_result = execute(folder_path, remote_url, options)
          
          # Add backup information to response
          if push_result[:success]
            push_result[:backup_created] = backup_result[:success]
            push_result[:backup_path] = backup_result[:backup_path] if backup_result[:success]
          end
          
          push_result
          
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

      def verify_repository_status(folder_path, options)
        repository_status = @git_operations.get_repository_status(folder_path)
        
        # Add additional validation
        if repository_status[:is_git_repository]
          # Check if there are any commits
          Dir.chdir(folder_path) do
            stdout, stderr, status = Open3.capture3('git rev-parse HEAD')
            repository_status[:has_commits] = status.success?
            
            if !repository_status[:has_commits] && !options[:allow_empty_repository]
              raise GitOperationError.new('push', 'Repository has no commits')
            end
          end
        end
        
        repository_status
      end

      def prepare_push_options(options, remote_url)
        push_options = {}
        
        # Basic push options
        push_options[:remote_name] = options[:remote_name] if options[:remote_name]
        push_options[:branch] = options[:branch] if options[:branch]
        push_options[:force] = options[:force] if options[:force]
        push_options[:set_upstream] = options[:set_upstream] if options[:set_upstream]
        
        # Commit options
        if options[:commit_changes]
          push_options[:add_all] = true
          push_options[:commit_message] = options[:commit_message] || "Template development update - #{Time.now}"
        end
        
        push_options
      end

      def validate_template_development_push(analysis, options)
        validation = {
          ready_for_push: false,
          issues: [],
          recommendations: []
        }
        
        folder_analysis = analysis[:folder_analysis]
        
        # Check basic folder status
        unless folder_analysis[:exists]
          validation[:issues] << "Folder does not exist"
          return validation
        end
        
        # Check if it's a meaningful template development folder
        unless folder_analysis[:is_git_repository] || folder_analysis[:has_template_configuration]
          validation[:issues] << "Folder is not a git repository and has no template configuration"
          validation[:recommendations] << "Initialize as git repository or add template configuration"
        end
        
        # Check template configuration validity if present
        if analysis[:template_configuration]
          template_config = analysis[:template_configuration]
          unless template_config[:valid]
            validation[:issues] << "Template configuration is invalid"
            validation[:recommendations] << "Fix template configuration errors before pushing"
          end
        end
        
        validation[:ready_for_push] = validation[:issues].empty?
        validation
      end

      def prepare_template_push_options(analysis, options)
        template_options = options.dup
        
        # Set default commit message for template development
        unless template_options[:commit_message]
          development_status = analysis[:development_status]
          template_options[:commit_message] = "Template development: #{development_status} - #{Time.now}"
        end
        
        # Enable automatic staging for template development
        template_options[:commit_changes] = true unless template_options.key?(:commit_changes)
        
        template_options
      end

      def create_push_backup(folder_path, options)
        begin
          timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
          backup_name = options[:backup_name] || "push_backup_#{timestamp}"
          backup_dir = options[:backup_dir] || File.join(File.dirname(folder_path), 'backups')
          
          FileUtils.mkdir_p(backup_dir)
          backup_path = File.join(backup_dir, backup_name)
          
          FileUtils.cp_r(folder_path, backup_path)
          
          {
            success: true,
            backup_path: backup_path,
            timestamp: timestamp
          }
        rescue => e
          {
            success: false,
            error: "Failed to create backup: #{e.message}"
          }
        end
      end

      def generate_push_success_response(push_result, repository_status, options)
        response = {
          success: true,
          operation: 'push',
          folder_path: push_result[:path],
          remote_url: push_result[:remote_url]
        }
        
        if repository_status[:initialized]
          response[:repository_initialized] = true
        end
        
        if push_result[:committed]
          response[:changes_committed] = true
        end
        
        if options[:verbose]
          response[:push_output] = push_result[:output]
          response[:repository_status] = repository_status
        end
        
        response
      end

      def handle_push_error(error, options)
        if options[:format] == :json
          {
            success: false,
            operation: 'push',
            error: error.message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: "Push failed: #{error.message}"
          }
        end
      end

      def handle_unexpected_error(error, options)
        error_message = "Unexpected error during push: #{error.message}"
        
        if options[:debug]
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        if options[:format] == :json
          {
            success: false,
            operation: 'push',
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