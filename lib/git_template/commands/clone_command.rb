# CloneCommand Class
#
# This command handles git repository cloning for template development,
# including URL validation, error handling for invalid URLs and existing directories,
# and integration with GitOperations service.

require_relative '../services/git_operations'
require_relative '../status_command_errors'

module GitTemplate
  module Commands
    class CloneCommand
      include StatusCommandErrors

      def initialize
        @git_operations = Services::GitOperations.new
      end

      def execute(git_url, target_folder = nil, options = {})
        begin
          # Validate and prepare parameters
          validated_url = validate_git_url(git_url)
          target_path = determine_target_path(git_url, target_folder)
          
          # Validate target path
          validate_target_path(target_path, options)
          
          # Perform clone operation
          clone_options = prepare_clone_options(options)
          result = @git_operations.clone_repository(validated_url, target_path, clone_options)
          
          # Generate success response
          generate_success_response(result, options)
          
        rescue StatusCommandError => e
          handle_clone_error(e, options)
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def clone_for_template_development(git_url, options = {})
        # Clone repository specifically for template development workflow
        begin
          # Determine target folder name from URL
          repo_name = extract_repository_name(git_url)
          target_folder = options[:target_folder] || repo_name
          
          # Clone the repository
          clone_result = execute(git_url, target_folder, options.merge(allow_existing: false))
          
          unless clone_result[:success]
            return clone_result
          end
          
          # Set up for template development
          setup_result = setup_for_template_development(clone_result[:target_path], options)
          
          {
            success: true,
            operation: 'clone_for_template_development',
            git_url: git_url,
            target_path: clone_result[:target_path],
            repository_name: repo_name,
            clone_result: clone_result,
            setup_result: setup_result
          }
          
        rescue => e
          handle_unexpected_error(e, options)
        end
      end

      def validate_clone_parameters(git_url, target_folder = nil)
        # Validate parameters without performing actual clone
        validation_results = {
          valid: true,
          issues: [],
          warnings: []
        }
        
        # Validate git URL
        begin
          validate_git_url(git_url)
        rescue GitOperationError => e
          validation_results[:valid] = false
          validation_results[:issues] << "Invalid git URL: #{e.message}"
        end
        
        # Validate target path if provided
        if target_folder
          begin
            target_path = File.expand_path(target_folder)
            
            if File.exist?(target_path)
              if File.directory?(target_path)
                unless Dir.empty?(target_path)
                  validation_results[:valid] = false
                  validation_results[:issues] << "Target directory exists and is not empty: #{target_path}"
                end
              else
                validation_results[:valid] = false
                validation_results[:issues] << "Target path exists and is not a directory: #{target_path}"
              end
            end
            
            # Check parent directory
            parent_dir = File.dirname(target_path)
            unless File.directory?(parent_dir)
              validation_results[:valid] = false
              validation_results[:issues] << "Parent directory does not exist: #{parent_dir}"
            end
          rescue => e
            validation_results[:valid] = false
            validation_results[:issues] << "Invalid target path: #{e.message}"
          end
        end
        
        validation_results
      end

      def check_repository_accessibility(git_url)
        # Check if repository is accessible without cloning
        begin
          validate_git_url(git_url)
          
          # Use git ls-remote to check accessibility
          cmd = "git ls-remote --heads #{git_url.shellescape}"
          stdout, stderr, status = Open3.capture3(cmd)
          
          if status.success?
            {
              accessible: true,
              url: git_url,
              heads: parse_remote_heads(stdout)
            }
          else
            {
              accessible: false,
              url: git_url,
              error: stderr.strip
            }
          end
        rescue GitOperationError => e
          {
            accessible: false,
            url: git_url,
            error: e.message
          }
        rescue => e
          {
            accessible: false,
            url: git_url,
            error: "Unexpected error: #{e.message}"
          }
        end
      end

      private

      def validate_git_url(url)
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

      def determine_target_path(git_url, target_folder)
        if target_folder
          File.expand_path(target_folder)
        else
          # Extract repository name from URL
          repo_name = extract_repository_name(git_url)
          File.expand_path(repo_name)
        end
      end

      def extract_repository_name(git_url)
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

      def validate_target_path(target_path, options)
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

      def prepare_clone_options(options)
        clone_options = {}
        
        clone_options[:quiet] = options[:quiet] if options.key?(:quiet)
        clone_options[:depth] = options[:depth] if options[:depth]
        clone_options[:branch] = options[:branch] if options[:branch]
        clone_options[:allow_existing] = options[:allow_existing] if options.key?(:allow_existing)
        
        clone_options
      end

      def setup_for_template_development(target_path, options)
        # Optional setup steps for template development
        setup_steps = []
        
        # Create .git_template directory if requested
        if options[:create_template_config]
          git_template_dir = File.join(target_path, '.git_template')
          unless File.directory?(git_template_dir)
            FileUtils.mkdir_p(git_template_dir)
            
            # Create basic template.rb file
            template_file = File.join(git_template_dir, 'template.rb')
            File.write(template_file, generate_basic_template_content)
            
            setup_steps << "Created .git_template directory with basic template.rb"
          end
        end
        
        # Create README for template development if requested
        if options[:create_readme]
          readme_file = File.join(target_path, 'TEMPLATE_DEVELOPMENT.md')
          unless File.exist?(readme_file)
            File.write(readme_file, generate_template_development_readme)
            setup_steps << "Created TEMPLATE_DEVELOPMENT.md"
          end
        end
        
        {
          setup_performed: setup_steps.any?,
          steps: setup_steps
        }
      end

      def generate_success_response(result, options)
        response = {
          success: true,
          operation: 'clone',
          git_url: result[:url],
          target_path: result[:target_path]
        }
        
        if options[:verbose]
          response[:output] = result[:output]
        end
        
        response
      end

      def parse_remote_heads(stdout)
        heads = []
        stdout.lines.each do |line|
          if line.match(/^([a-f0-9]+)\s+refs\/heads\/(.+)$/)
            heads << { commit: $1, branch: $2 }
          end
        end
        heads
      end

      def generate_basic_template_content
        <<~RUBY
          # Basic Rails Template
          # Generated by git-template clone command
          
          say "Applying basic template..."
          
          # Add your template logic here
          
          say "Template application complete!"
        RUBY
      end

      def generate_template_development_readme
        <<~MARKDOWN
          # Template Development
          
          This repository has been cloned for template development using git-template.
          
          ## Next Steps
          
          1. Review the application structure
          2. Create or update the `.git_template/template.rb` file
          3. Test the template using `git-template iterate`
          4. Refine the template based on comparison results
          
          ## Commands
          
          - `git-template status .` - Check template development status
          - `git-template iterate .` - Test and refine the template
          - `git-template update .` - Update template configuration
          
          Generated by git-template v#{GitTemplate::VERSION rescue 'unknown'}
        MARKDOWN
      end

      def handle_clone_error(error, options)
        if options[:format] == :json
          {
            success: false,
            operation: 'clone',
            error: error.message,
            error_type: error.class.name
          }
        else
          {
            success: false,
            error: "Clone failed: #{error.message}"
          }
        end
      end

      def handle_unexpected_error(error, options)
        error_message = "Unexpected error during clone: #{error.message}"
        
        if options[:debug]
          error_message += "\nBacktrace:\n#{error.backtrace.join("\n")}"
        end
        
        if options[:format] == :json
          {
            success: false,
            operation: 'clone',
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