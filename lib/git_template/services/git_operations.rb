# GitOperations Service
#
# This service provides git operation functionality including cloning,
# pushing, repository initialization, and status checking with comprehensive
# error handling for network and authentication issues.

require 'open3'
require 'uri'
require_relative '../status_command_errors'

module GitTemplate
  module Services
    class GitOperations
      include StatusCommandErrors

      def initialize
        # Service is stateless, no initialization needed
      end

      def clone_repository(url, target_path, options = {})
        validate_git_url(url)
        validate_target_path(target_path, options[:allow_existing] || false)
        
        begin
          # Ensure parent directory exists
          FileUtils.mkdir_p(File.dirname(target_path))
          
          # Execute git clone
          cmd = build_clone_command(url, target_path, options)
          stdout, stderr, status = Open3.capture3(cmd)
          
          unless status.success?
            raise GitOperationError.new('clone', "#{stderr.strip}\nCommand: #{cmd}")
          end
          
          # Verify the clone was successful
          unless File.directory?(File.join(target_path, '.git'))
            raise GitOperationError.new('clone', 'Repository was not properly cloned')
          end
          
          {
            success: true,
            target_path: target_path,
            url: url,
            output: stdout.strip
          }
        rescue => e
          if e.is_a?(GitOperationError)
            raise e
          else
            raise GitOperationError.new('clone', e.message)
          end
        end
      end

      def initialize_repository(path)
        unless File.directory?(path)
          raise InvalidPathError.new(path)
        end
        
        # Don't initialize if already a git repository
        if is_git_repository?(path)
          return {
            success: true,
            path: path,
            message: 'Repository already initialized'
          }
        end
        
        begin
          Dir.chdir(path) do
            stdout, stderr, status = Open3.capture3('git init')
            
            unless status.success?
              raise GitOperationError.new('init', stderr.strip)
            end
            
            {
              success: true,
              path: path,
              output: stdout.strip
            }
          end
        rescue => e
          if e.is_a?(GitOperationError)
            raise e
          else
            raise GitOperationError.new('init', e.message)
          end
        end
      end

      def push_to_remote(path, remote_url = nil, options = {})
        unless is_git_repository?(path)
          raise GitOperationError.new('push', 'Not a git repository')
        end
        
        begin
          Dir.chdir(path) do
            # Add remote if provided and doesn't exist
            if remote_url
              setup_remote(remote_url, options[:remote_name] || 'origin')
            end
            
            # Stage all changes if requested
            if options[:add_all]
              stdout, stderr, status = Open3.capture3('git add .')
              unless status.success?
                raise GitOperationError.new('add', stderr.strip)
              end
            end
            
            # Commit if there are staged changes and commit message provided
            if options[:commit_message]
              commit_result = commit_changes(options[:commit_message])
            end
            
            # Push to remote
            push_cmd = build_push_command(options)
            stdout, stderr, status = Open3.capture3(push_cmd)
            
            unless status.success?
              raise GitOperationError.new('push', "#{stderr.strip}\nCommand: #{push_cmd}")
            end
            
            {
              success: true,
              path: path,
              remote_url: remote_url,
              output: stdout.strip,
              committed: !options[:commit_message].nil?
            }
          end
        rescue => e
          if e.is_a?(GitOperationError)
            raise e
          else
            raise GitOperationError.new('push', e.message)
          end
        end
      end

      def get_repository_status(path)
        unless is_git_repository?(path)
          return {
            is_git_repository: false,
            path: path
          }
        end
        
        begin
          Dir.chdir(path) do
            # Get basic status
            stdout, stderr, status = Open3.capture3('git status --porcelain')
            unless status.success?
              raise GitOperationError.new('status', stderr.strip)
            end
            
            # Get remote information
            remote_stdout, remote_stderr, remote_status = Open3.capture3('git remote -v')
            remotes = remote_status.success? ? parse_remotes(remote_stdout) : {}
            
            # Get current branch
            branch_stdout, branch_stderr, branch_status = Open3.capture3('git branch --show-current')
            current_branch = branch_status.success? ? branch_stdout.strip : 'unknown'
            
            {
              is_git_repository: true,
              path: path,
              has_changes: !stdout.strip.empty?,
              status_output: stdout.strip,
              current_branch: current_branch,
              remotes: remotes
            }
          end
        rescue => e
          if e.is_a?(GitOperationError)
            raise e
          else
            raise GitOperationError.new('status', e.message)
          end
        end
      end

      def is_git_repository?(path)
        File.directory?(File.join(path, '.git'))
      end

      private

      def validate_git_url(url)
        # Basic URL validation
        begin
          uri = URI.parse(url)
          unless uri.scheme && (uri.scheme.match?(/^https?$/) || uri.scheme == 'git' || url.include?('@'))
            raise GitOperationError.new('clone', "Invalid git URL format: #{url}")
          end
        rescue URI::InvalidURIError
          # Try to handle SSH URLs like git@github.com:user/repo.git
          unless url.match?(/^[\w\-\.]+@[\w\-\.]+:[\w\-\.\/]+\.git$/)
            raise GitOperationError.new('clone', "Invalid git URL format: #{url}")
          end
        end
      end

      def validate_target_path(target_path, allow_existing)
        if File.exist?(target_path) && !allow_existing
          if File.directory?(target_path)
            # Check if directory is empty
            unless Dir.empty?(target_path)
              raise GitOperationError.new('clone', "Target directory exists and is not empty: #{target_path}")
            end
          else
            raise GitOperationError.new('clone', "Target path exists and is not a directory: #{target_path}")
          end
        end
      end

      def build_clone_command(url, target_path, options)
        cmd_parts = ['git', 'clone']
        
        # Add options
        cmd_parts << '--quiet' if options[:quiet]
        cmd_parts << '--depth' << options[:depth].to_s if options[:depth]
        cmd_parts << '--branch' << options[:branch] if options[:branch]
        
        cmd_parts << url << target_path
        cmd_parts.join(' ')
      end

      def setup_remote(remote_url, remote_name)
        # Check if remote already exists
        stdout, stderr, status = Open3.capture3("git remote get-url #{remote_name}")
        
        if status.success?
          # Remote exists, update URL if different
          existing_url = stdout.strip
          if existing_url != remote_url
            stdout, stderr, status = Open3.capture3("git remote set-url #{remote_name} #{remote_url}")
            unless status.success?
              raise GitOperationError.new('remote set-url', stderr.strip)
            end
          end
        else
          # Remote doesn't exist, add it
          stdout, stderr, status = Open3.capture3("git remote add #{remote_name} #{remote_url}")
          unless status.success?
            raise GitOperationError.new('remote add', stderr.strip)
          end
        end
      end

      def commit_changes(message)
        # Check if there are staged changes
        stdout, stderr, status = Open3.capture3('git diff --cached --quiet')
        
        # If exit code is 1, there are staged changes to commit
        if status.exitstatus == 1
          stdout, stderr, status = Open3.capture3("git commit -m #{message.shellescape}")
          unless status.success?
            raise GitOperationError.new('commit', stderr.strip)
          end
          return { committed: true, output: stdout.strip }
        else
          return { committed: false, message: 'No staged changes to commit' }
        end
      end

      def build_push_command(options)
        cmd_parts = ['git', 'push']
        
        remote_name = options[:remote_name] || 'origin'
        branch_name = options[:branch] || 'HEAD'
        
        cmd_parts << remote_name << branch_name
        cmd_parts << '--force' if options[:force]
        cmd_parts << '--set-upstream' if options[:set_upstream]
        
        cmd_parts.join(' ')
      end

      def parse_remotes(remote_output)
        remotes = {}
        remote_output.lines.each do |line|
          if line.match(/^(\w+)\s+(.+)\s+\((fetch|push)\)$/)
            name, url, type = $1, $2, $3
            remotes[name] ||= {}
            remotes[name][type] = url
          end
        end
        remotes
      end
    end
  end
end