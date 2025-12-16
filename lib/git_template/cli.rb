require "thor"
require_relative "commands/status_command"
require_relative "commands/clone_command"
require_relative "commands/iterate_command"
require_relative "commands/update_command"
require_relative "commands/push_command"

module GitTemplate
  class CLI < Thor
    desc "apply [PATH]", "Apply the git-template to current directory or specified path"
    option :rails_new, type: :boolean, default: false, desc: "Create new Rails application"
    def apply(path = ".")
      begin
        if options[:rails_new]
          puts "Creating new Rails application with git-template..."
          # This would be used with: rails new myapp -m git-template
          puts "Use: rails new myapp -m git-template"
          return
        end
        
        puts "Applying git-template to #{File.expand_path(path)}..."
        
        # Check if we're in a Rails application directory
        unless File.exist?(File.join(path, "config", "application.rb"))
          puts "Error: Not a Rails application directory. Please run from Rails app root or use --rails-new option."
          exit 1
        end
        
        # Apply template to existing Rails app
        Dir.chdir(path) do
          template_path = TemplateResolver.gem_template_path
          puts "Using template: #{template_path}"
          
          # Execute the template using Rails' template system
          system("bin/rails app:template LOCATION=#{template_path}")
        end
        
        puts "\n" + "=" * 60
        puts "✅ git-template application completed successfully!"
        puts "=" * 60
        puts "\nYour Rails application has been enhanced with:"
        puts "  • Structured template lifecycle management"
        puts "  • Modern frontend setup (Vite, Tailwind, Juris.js)"
        puts "  • Organized phase-based configuration"
        puts "\nNext steps:"
        puts "  1. Start the development server: bin/dev"
        puts "  2. Visit http://localhost:3000"
        puts "  3. Explore the template structure in template/ directory"
        puts "\nFor more information: git-template help"
        
      rescue => e
        puts "❌ Error applying template: #{e.message}"
        puts e.backtrace if ENV["DEBUG"]
        exit 1
      end
    end

    desc "version", "Show git-template version"
    def version
      puts "git-template version #{GitTemplate::VERSION}"
    end

    desc "list", "List available templates"
    def list
      puts "Available templates:"
      puts "  • Rails 8 + Juris.js (default) - Modern Rails app with Juris.js frontend"
    end

    desc "path", "Show path to bundled template"
    def path
      puts TemplateResolver.gem_template_path
    end

    # New status command system commands
    desc "status FOLDER", "Check the status of application folders for template development"
    option :format, type: :string, default: "detailed", desc: "Output format: detailed, summary, json"
    option :verbose, type: :boolean, default: false, desc: "Show verbose output"
    option :debug, type: :boolean, default: false, desc: "Show debug information"
    def status(folder_path)
      setup_environment(options)
      
      begin
        command = Commands::StatusCommand.new
        result = command.execute(folder_path, options.to_h.symbolize_keys)
        
        if result[:success]
          puts result[:report] if result[:report]
          puts result[:summary] if result[:summary] && !result[:report]
        else
          handle_command_error("status", result)
        end
      rescue => e
        handle_unexpected_command_error("status", e, options)
      end
    end

    desc "clone GIT_URL [TARGET_FOLDER]", "Clone remote applications for template development"
    option :branch, type: :string, desc: "Specific branch to clone"
    option :depth, type: :numeric, desc: "Create shallow clone with specified depth"
    option :quiet, type: :boolean, default: false, desc: "Suppress output"
    option :create_template_config, type: :boolean, default: false, desc: "Create basic template configuration"
    option :debug, type: :boolean, default: false, desc: "Show debug information"
    def clone(git_url, target_folder = nil)
      setup_environment(options)
      validate_command_prerequisites
      
      begin
        command = Commands::CloneCommand.new
        result = command.execute(git_url, target_folder, options.to_h.symbolize_keys)
        
        if result[:success]
          puts "✅ Successfully cloned #{result[:git_url]} to #{result[:target_path]}"
        else
          handle_command_error("clone", result)
        end
      rescue => e
        handle_unexpected_command_error("clone", e, options)
      end
    end

    desc "iterate FOLDER", "Iterate on templates to refine accuracy through comparison"
    option :detailed_comparison, type: :boolean, default: false, desc: "Show detailed comparison results"
    option :create_templated_folder, type: :boolean, default: false, desc: "Create templated folder if it doesn't exist"
    option :verbose, type: :boolean, default: false, desc: "Show verbose output"
    option :debug, type: :boolean, default: false, desc: "Show debug information"
    def iterate(folder_path)
      setup_environment(options)
      
      begin
        command = Commands::IterateCommand.new
        result = command.execute(folder_path, options.to_h.symbolize_keys)
        
        if result[:success]
          puts "✅ Template iteration completed"
          puts "   Application folder: #{result[:application_folder]}"
          puts "   Templated folder: #{result[:templated_folder]}"
          puts "   Template applied: #{result[:template_applied] ? 'Yes' : 'No'}"
          puts "   Differences found: #{result[:differences_count]} changes"
          puts "   Cleanup updated: #{result[:cleanup_updated] ? 'Yes' : 'No'}"
        else
          handle_command_error("iterate", result)
        end
      rescue => e
        handle_unexpected_command_error("iterate", e, options)
      end
    end

    desc "update FOLDER", "Update templates to incorporate refinements and maintain accuracy"
    option :refresh_structure, type: :boolean, default: false, desc: "Refresh template structure analysis"
    option :fix_issues, type: :boolean, default: false, desc: "Fix common template issues"
    option :update_metadata, type: :boolean, default: false, desc: "Update template metadata"
    option :all, type: :boolean, default: false, desc: "Perform all update operations"
    option :verbose, type: :boolean, default: false, desc: "Show verbose output"
    option :debug, type: :boolean, default: false, desc: "Show debug information"
    def update(folder_path)
      setup_environment(options)
      
      begin
        command = Commands::UpdateCommand.new
        result = command.execute(folder_path, options.to_h.symbolize_keys)
        
        if result[:success]
          puts "✅ Template update completed"
          puts "   Operations performed: #{result[:operations_performed].length}"
          result[:operations_performed].each { |op| puts "   - #{op}" }
          
          validation = result[:validation_result]
          puts "   Template valid: #{validation[:valid] ? 'Yes' : 'No'}"
          if validation[:validation_errors].any?
            puts "   Validation errors:"
            validation[:validation_errors].each { |error| puts "     - #{error}" }
          end
        else
          handle_command_error("update", result)
        end
      rescue => e
        handle_unexpected_command_error("update", e, options)
      end
    end

    desc "push FOLDER [REMOTE_URL]", "Push application folders to remote repositories"
    option :remote_name, type: :string, default: "origin", desc: "Remote name to use"
    option :branch, type: :string, desc: "Branch to push"
    option :commit_changes, type: :boolean, default: false, desc: "Commit changes before pushing"
    option :commit_message, type: :string, desc: "Commit message to use"
    option :initialize_if_needed, type: :boolean, default: false, desc: "Initialize git repository if needed"
    option :force, type: :boolean, default: false, desc: "Force push"
    option :verbose, type: :boolean, default: false, desc: "Show verbose output"
    option :debug, type: :boolean, default: false, desc: "Show debug information"
    def push(folder_path, remote_url = nil)
      setup_environment(options)
      validate_command_prerequisites
      
      begin
        command = Commands::PushCommand.new
        result = command.execute(folder_path, remote_url, options.to_h.symbolize_keys)
        
        if result[:success]
          puts "✅ Successfully pushed #{result[:folder_path]}"
          puts "   Remote URL: #{result[:remote_url]}" if result[:remote_url]
          puts "   Repository initialized: Yes" if result[:repository_initialized]
          puts "   Changes committed: Yes" if result[:changes_committed]
        else
          handle_command_error("push", result)
        end
      rescue => e
        handle_unexpected_command_error("push", e, options)
      end
    end

    desc "test", "Test git-template with a specific templated app"
    option :templated_app_path, type: :string, required: true, desc: "Path to templated app (e.g., examples/rails/rails8-juris)"
    def test
      require "fileutils"
      require "tmpdir"
      require "time"
      
      templated_app_path = options[:templated_app_path]
      
      # Create log directory and timestamp
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      log_dir = File.join(Dir.pwd, "log", "git-template-test", timestamp)
      FileUtils.mkdir_p(log_dir)
      
      # Create log files
      main_log = File.join(log_dir, "test_execution.log")
      git_status_log = File.join(log_dir, "git_status.log")
      git_diff_log = File.join(log_dir, "git_diff.log")
      summary_log = File.join(log_dir, "summary.log")
      
      puts "🧪 Starting git-template test..."
      puts "Templated app path: #{templated_app_path}"
      puts "📁 Logs will be saved to: #{log_dir}"
      
      # Start logging
      File.open(main_log, 'w') do |log|
        log.puts "Git Template Test Execution Log"
        log.puts "=" * 50
        log.puts "Timestamp: #{Time.now}"
        log.puts "Templated app path: #{templated_app_path}"
        log.puts "Log directory: #{log_dir}"
        log.puts "=" * 50
        log.puts ""
      
        # Step 1: Confirm .git_template path exists
        git_template_root = File.expand_path("../..", __dir__)
        puts "\n1️⃣ Checking .git_template path..."
        puts "Git template root: #{git_template_root}"
        log.puts "1️⃣ Checking .git_template path..."
        log.puts "Git template root: #{git_template_root}"
        
        unless File.directory?(git_template_root)
          error_msg = "❌ Error: .git_template path does not exist: #{git_template_root}"
          puts error_msg
          log.puts error_msg
          exit 1
        end
        puts "✅ .git_template path exists"
        log.puts "✅ .git_template path exists"
      
        # Step 2: Validate .git_template contents
        puts "\n2️⃣ Validating .git_template contents..."
        log.puts "\n2️⃣ Validating .git_template contents..."
        
        # Check for git-template library
        lib_path = File.join(git_template_root, "lib/git_template.rb")
        unless File.exist?(lib_path)
          error_msg = "❌ Error: Required path missing: lib/git_template.rb"
          puts error_msg
          log.puts error_msg
          exit 1
        end
        puts "✅ Found: lib/git_template.rb"
        log.puts "✅ Found: lib/git_template.rb"
        
        # Check for the templated app path
        app_path = File.join(git_template_root, templated_app_path)
        unless File.exist?(app_path)
          error_msg = "❌ Error: Required path missing: #{templated_app_path}"
          puts error_msg
          log.puts error_msg
          exit 1
        end
        puts "✅ Found: #{templated_app_path}"
        log.puts "✅ Found: #{templated_app_path}"
        
        # Check for template file in the app
        template_file = File.join(app_path, ".git_template/template.rb")
        unless File.exist?(template_file)
          error_msg = "❌ Error: Required template file missing: #{templated_app_path}/.git_template/template.rb"
          puts error_msg
          log.puts error_msg
          exit 1
        end
        puts "✅ Found: #{templated_app_path}/.git_template/template.rb"
        log.puts "✅ Found: #{templated_app_path}/.git_template/template.rb"
      
        # Step 3: Create folder template_test
        puts "\n3️⃣ Creating template_test folder..."
        log.puts "\n3️⃣ Creating template_test folder..."
        test_dir = File.join(Dir.pwd, "template_test")
        
        if File.exist?(test_dir)
          cleanup_msg = "🗑️  Removing existing template_test directory..."
          puts cleanup_msg
          log.puts cleanup_msg
          FileUtils.rm_rf(test_dir)
        end
        
        FileUtils.mkdir_p(test_dir)
        created_msg = "✅ Created: #{test_dir}"
        puts created_msg
        log.puts created_msg
      
        # Step 4: Copy JUST the template folder to template_test/[templated_app_path]
        puts "\n4️⃣ Copying template to test directory..."
        log.puts "\n4️⃣ Copying template to test directory..."
        source_path = File.join(git_template_root, templated_app_path)
        dest_path = File.join(test_dir, templated_app_path)
        
        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp_r(source_path, dest_path)
        copy_msg = "✅ Copied #{templated_app_path} to #{dest_path}"
        puts copy_msg
        log.puts copy_msg
      
        # Step 5: Clean up files to remove problematic references
        puts "\n5️⃣ Cleaning up files for testing..."
        log.puts "\n5️⃣ Cleaning up files for testing..."
        
        # Clean up Gemfile
        gemfile_path = File.join(dest_path, "Gemfile")
        if File.exist?(gemfile_path)
          gemfile_content = File.read(gemfile_path)
          
          # Comment out problematic path-based gems
          problematic_patterns = [
            /^gem\s+["']active_data_flow.*$/,
            /^gem\s+["']redis-emulator.*$/,
            /^#gem\s+['"]submoduler-core.*$/
          ]
          
          problematic_patterns.each do |pattern|
            gemfile_content.gsub!(pattern) { |match| "# #{match} # Commented out for testing" }
          end
          
          File.write(gemfile_path, gemfile_content)
          gemfile_msg = "✅ Cleaned up Gemfile"
          puts gemfile_msg
          log.puts gemfile_msg
        end
        
        # Clean up boot.rb
        boot_path = File.join(dest_path, "config", "boot.rb")
        if File.exist?(boot_path)
          boot_content = File.read(boot_path)
          boot_content.gsub!(/^require\s+['"]active_data_flow['"].*$/, "# require 'active_data_flow' # Commented out for testing")
          File.write(boot_path, boot_content)
          boot_msg = "✅ Cleaned up boot.rb"
          puts boot_msg
          log.puts boot_msg
        end
        
        # Clean up or remove ActiveDataFlow initializer
        initializer_path = File.join(dest_path, "config", "initializers", "active_data_flow.rb")
        if File.exist?(initializer_path)
          File.delete(initializer_path)
          init_msg = "✅ Removed ActiveDataFlow initializer"
          puts init_msg
          log.puts init_msg
        end
      
        # Step 6: Run the template and capture git diff
        puts "\n6️⃣ Running git-template and capturing changes..."
        log.puts "\n6️⃣ Running git-template and capturing changes..."
        
        # Initialize template_result variable before Dir.chdir block
        template_result = false
        
        Dir.chdir(dest_path) do
          # Initialize git repo if not exists
          unless File.directory?(".git")
            git_init_msg = "📝 Initializing git repository..."
            puts git_init_msg
            log.puts git_init_msg
            system("git init", out: File::NULL, err: File::NULL)
            system("git add .", out: File::NULL, err: File::NULL)
            system("git commit -m 'Initial commit before template'", out: File::NULL, err: File::NULL)
          end
          
          # Install gems first
          bundle_msg = "📦 Installing gems..."
          puts bundle_msg
          log.puts bundle_msg
          system("bundle install")
          
          # Apply the template
          # First check if there's a local .git_template/template.rb
          local_template_path = File.join(Dir.pwd, ".git_template", "template.rb")
          template_path = if File.exist?(local_template_path)
            local_template_path
          else
            File.join(git_template_root, "template.rb")
          end
          
          template_msg = "🔧 Applying template: #{template_path}"
          puts template_msg
          log.puts template_msg
          
          # Run the template (assuming it's a Rails app)
          if File.exist?("bin/rails")
            # Set environment variables to make template non-interactive
            env_vars = {
              "RAILS_TEMPLATE_NON_INTERACTIVE" => "true",
              "TEMPLATE_USE_REDIS" => "false",
              "TEMPLATE_USE_ACTIVE_DATA_FLOW" => "false", 
              "TEMPLATE_USE_DOCKER" => "false",
              "TEMPLATE_GENERATE_SAMPLE_MODELS" => "false",
              "TEMPLATE_SETUP_ADMIN" => "false",
              "THOR_MERGE" => "true",  # Auto-overwrite files without prompting
              "THOR_SHELL" => "Basic",  # Use basic shell (non-interactive)
              "RAILS_ENV" => "development"  # Ensure consistent environment
            }
            
            puts "Environment variables:"
            log.puts "Environment variables:"
            env_vars.each do |k, v| 
              env_line = "  #{k}=#{v}"
              puts env_line
              log.puts env_line
            end
            puts ""
            log.puts ""
            
            # Use non-interactive template execution
            template_result = execute_template_non_interactive(template_path, env_vars, log)
            result_msg = "Template execution result: #{template_result}"
            puts result_msg
            log.puts result_msg
          else
            warning_msg = "⚠️  Warning: Not a Rails app, skipping template application"
            puts warning_msg
            log.puts warning_msg
            template_result = true  # Consider it successful if no Rails app to process
          end
          
          # Capture git status and diff to separate log files
          puts "\n📊 Capturing git changes to log files..."
          log.puts "\n📊 Capturing git changes to log files..."
          
          # Capture git status
          status_output = `git status --porcelain`
          File.write(git_status_log, status_output)
          
          # Capture git diff
          system("git add .")
          diff_output = `git diff --cached --no-color`
          File.write(git_diff_log, diff_output)
          
          # Show status on console
          puts "\n📋 Git Status:"
          puts status_output
          
          # Count changes for summary
          modified_files = status_output.lines.select { |line| line.start_with?(' M') }.count
          new_files = status_output.lines.select { |line| line.start_with?('??') }.count
          deleted_files = status_output.lines.select { |line| line.start_with?(' D') }.count
          
          # Check if template is repeatable (no changes on second run)
          total_changes = modified_files + new_files + deleted_files
          is_repeatable = total_changes == 0 && template_result
          
          # Determine test result
          test_result = if is_repeatable
            "✅ No difference, test passed"
          elsif template_result && total_changes > 0
            "⚠️  Template applied successfully but made changes"
          else
            "❌ Template execution failed or had errors"
          end
          
          # Create summary
          summary_content = <<~SUMMARY
            Git Template Test Summary
            ========================
            Timestamp: #{Time.now}
            Templated app path: #{templated_app_path}
            Test directory: #{dest_path}
            
            Results:
            • #{modified_files} files modified
            • #{new_files} new files created
            • #{deleted_files} files deleted
            • Template execution: #{template_result ? 'SUCCESS' : 'FAILED'}
            • Test result: #{test_result}
            
            Repeatability: #{is_repeatable ? 'PASSED - Template is idempotent' : 'FAILED - Template makes changes on repeat runs'}
            
            Log Files:
            • Main execution log: #{main_log}
            • Git status: #{git_status_log}
            • Git diff: #{git_diff_log}
            • This summary: #{summary_log}
          SUMMARY
          
          File.write(summary_log, summary_content)
          
          puts "\n📊 Summary:"
          puts "  • #{modified_files} files modified"
          puts "  • #{new_files} new files created"
          puts "  • #{deleted_files} files deleted"
          puts "  • Template execution: #{template_result ? 'SUCCESS' : 'FAILED'}"
          puts ""
          puts "🔄 Repeatability Test:"
          if is_repeatable
            puts "  ✅ No difference, test passed"
            puts "  📋 Template is idempotent (safe to run multiple times)"
          else
            puts "  ⚠️  Template made changes on this run"
            puts "  📋 This may be expected for first-time application"
          end
          puts ""
          puts "📁 Test results available in: #{dest_path}"
          puts "📋 Logs saved to: #{log_dir}"
          puts "  • Main log: #{File.basename(main_log)}"
          puts "  • Git status: #{File.basename(git_status_log)}"
          puts "  • Git diff: #{File.basename(git_diff_log)}"
          puts "  • Summary: #{File.basename(summary_log)}"
          
          log.puts "\n📊 Summary:"
          log.puts "  • #{modified_files} files modified"
          log.puts "  • #{new_files} new files created"
          log.puts "  • #{deleted_files} files deleted"
          log.puts "  • Template execution: #{template_result ? 'SUCCESS' : 'FAILED'}"
          log.puts "  • Test result: #{test_result}"
          log.puts "  • Repeatability: #{is_repeatable ? 'PASSED' : 'FAILED'}"
          log.puts "📁 Test results available in: #{dest_path}"
          log.puts "📋 Logs saved to: #{log_dir}"
        end
      end
      
    rescue => e
      error_msg = "❌ Error during template test: #{e.message}"
      puts error_msg
      
      # Log error if log file is available
      if defined?(log) && log
        log.puts error_msg
        log.puts "Backtrace:" if ENV["DEBUG"]
        log.puts e.backtrace.join("\n") if ENV["DEBUG"]
      end
      
      puts e.backtrace if ENV["DEBUG"]
      exit 1
    end

    desc "check_target", "Apply template to target app and compare with templated version"
    option :target, type: :string, required: true, desc: "Path to base Rails app (e.g., examples/rails/rails8-juris)"
    option :templated, type: :string, required: true, desc: "Path to templated version with .git_template (e.g., templated/examples/rails/rails8-juris)"
    def check_target
      require "fileutils"
      require "time"
      
      target_path = options[:target]
      templated_path = options[:templated]
      
      # Create log directory and timestamp
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      log_dir = File.join(Dir.pwd, "log", "check-target", timestamp)
      FileUtils.mkdir_p(log_dir)
      
      # Create log files
      main_log = File.join(log_dir, "check_execution.log")
      diff_log = File.join(log_dir, "differences.log")
      summary_log = File.join(log_dir, "summary.log")
      
      puts "🔍 Starting target comparison..."
      puts "Target template: #{target_path}"
      puts "Templated version: #{templated_path}"
      puts "📁 Logs will be saved to: #{log_dir}"
      
      # Start logging
      File.open(main_log, 'w') do |log|
        log.puts "Git Template Target Comparison Log"
        log.puts "=" * 50
        log.puts "Timestamp: #{Time.now}"
        log.puts "Target template: #{target_path}"
        log.puts "Templated version: #{templated_path}"
        log.puts "Log directory: #{log_dir}"
        log.puts "=" * 50
        log.puts ""
        
        begin
          # Step 1: Validate paths exist
          puts "\n1️⃣ Validating paths..."
          log.puts "1️⃣ Validating paths..."
          
          git_template_root = File.expand_path(Dir.pwd)
          target_full_path = File.join(git_template_root, target_path)
          templated_full_path = File.join(git_template_root, templated_path)
          
          unless File.directory?(target_full_path)
            error_msg = "❌ Target path does not exist: #{target_full_path}"
            puts error_msg
            log.puts error_msg
            exit 1
          end
          
          unless File.directory?(templated_full_path)
            error_msg = "❌ Templated path does not exist: #{templated_full_path}"
            puts error_msg
            log.puts error_msg
            exit 1
          end
          
          templated_template_file = File.join(templated_full_path, ".git_template", "template.rb")
          unless File.exist?(templated_template_file)
            error_msg = "❌ Templated version template file not found: #{templated_template_file}"
            puts error_msg
            log.puts error_msg
            exit 1
          end
          
          success_msg = "✅ All paths validated successfully"
          puts success_msg
          log.puts success_msg
          
          # Step 2: Apply template to target and compare with templated version
          puts "\n2️⃣ Creating temporary test environment..."
          log.puts "2️⃣ Creating temporary test environment..."
          
          # Create temporary directory for testing
          test_dir = File.join(Dir.pwd, "template_test_comparison")
          FileUtils.rm_rf(test_dir) if File.exist?(test_dir)
          FileUtils.mkdir_p(test_dir)
          
          # Copy target to test directory and add template from templated version
          target_test_path = File.join(test_dir, "target_applied")
          FileUtils.cp_r(target_full_path, target_test_path)
          
          # Copy the .git_template directory from templated version to target copy
          templated_git_template = File.join(templated_full_path, ".git_template")
          target_git_template = File.join(target_test_path, ".git_template")
          FileUtils.cp_r(templated_git_template, target_git_template)
          
          # Clean up problematic files for testing
          cleanup_msg = "🧹 Cleaning up files for testing..."
          puts cleanup_msg
          log.puts cleanup_msg
          
          # Clean up Gemfile
          gemfile_path = File.join(target_test_path, "Gemfile")
          if File.exist?(gemfile_path)
            gemfile_content = File.read(gemfile_path)
            
            # Remove problematic gem references (path-based gems that won't exist)
            problematic_patterns = [
              /^gem\s+["']active_data_flow["'].*$/,
              /^gem\s+["']active_data_flow-.*$/,
              /^gem\s+["']redis-emulator["'].*$/,
              /^gem\s+["']submoduler-core.*$/,
              /^#gem\s+["']submoduler-core.*$/,
              /path:\s*["'][^"']*active_data_flow[^"']*["']/,
              /path:\s*["'][^"']*redis-emulator[^"']*["']/,
              /path:\s*["'][^"']*submoduler[^"']*["']/
            ]
            
            problematic_patterns.each do |pattern|
              gemfile_content.gsub!(pattern) { |match| "# #{match} # Commented out for testing" }
            end
            
            File.write(gemfile_path, gemfile_content)
            cleanup_gemfile_msg = "✅ Cleaned up Gemfile (removed path-based gems)"
            puts cleanup_gemfile_msg
            log.puts cleanup_gemfile_msg
          end
          
          # Clean up boot.rb
          boot_path = File.join(target_test_path, "config", "boot.rb")
          if File.exist?(boot_path)
            boot_content = File.read(boot_path)
            boot_content.gsub!(/^require\s+['"]active_data_flow['"].*$/, "# require 'active_data_flow' # Commented out for testing")
            File.write(boot_path, boot_content)
            cleanup_boot_msg = "✅ Cleaned up boot.rb"
            puts cleanup_boot_msg
            log.puts cleanup_boot_msg
          end
          
          # Clean up or remove problematic initializers
          problematic_initializers = [
            "active_data_flow.rb",
            "redis_emulator.rb",
            "submoduler.rb"
          ]
          
          problematic_initializers.each do |initializer|
            initializer_path = File.join(target_test_path, "config", "initializers", initializer)
            if File.exist?(initializer_path)
              File.delete(initializer_path)
              cleanup_init_msg = "✅ Removed #{initializer} initializer"
              puts cleanup_init_msg
              log.puts cleanup_init_msg
            end
          end
          
          # Clean up application.rb if it has problematic requires
          app_rb_path = File.join(target_test_path, "config", "application.rb")
          if File.exist?(app_rb_path)
            app_content = File.read(app_rb_path)
            original_content = app_content.dup
            
            # Comment out problematic requires
            app_content.gsub!(/^require\s+['"]active_data_flow['"].*$/, "# require 'active_data_flow' # Commented out for testing")
            app_content.gsub!(/^require\s+['"]redis-emulator['"].*$/, "# require 'redis-emulator' # Commented out for testing")
            app_content.gsub!(/^require\s+['"]submoduler.*['"].*$/, "# require 'submoduler' # Commented out for testing")
            
            if app_content != original_content
              File.write(app_rb_path, app_content)
              cleanup_app_msg = "✅ Cleaned up application.rb"
              puts cleanup_app_msg
              log.puts cleanup_app_msg
            end
          end
          
          test_msg = "✅ Test environment created: #{test_dir}"
          puts test_msg
          log.puts test_msg
          
          # Step 3: Apply template to target copy
          puts "\n3️⃣ Applying template to target copy..."
          log.puts "3️⃣ Applying template to target copy..."
          
          # Initialize template_result variable
          template_result = false
          
          Dir.chdir(target_test_path) do
            # Initialize git repo if not exists
            unless File.directory?(".git")
              system("git init", out: File::NULL, err: File::NULL)
              system("git add .", out: File::NULL, err: File::NULL)
              system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
            end
            
            # Install npm dependencies first if package.json exists
            if File.exist?("package.json")
              npm_msg = "📦 Installing npm dependencies..."
              puts npm_msg
              log.puts npm_msg
              system("npm install")
            end
            
            # Apply the template
            template_path = File.join(Dir.pwd, ".git_template", "template.rb")
            
            if File.exist?("bin/rails")
              # Set environment variables for non-interactive mode
              env_vars = {
                "RAILS_TEMPLATE_NON_INTERACTIVE" => "true",
                "TEMPLATE_USE_REDIS" => "false",
                "TEMPLATE_USE_ACTIVE_DATA_FLOW" => "false", 
                "TEMPLATE_USE_DOCKER" => "false",
                "TEMPLATE_GENERATE_SAMPLE_MODELS" => "false",
                "TEMPLATE_SETUP_ADMIN" => "false",
                "THOR_MERGE" => "true",
                "THOR_SHELL" => "Basic",
                "RAILS_ENV" => "development"
              }
              
              # Use non-interactive template execution
              template_result = execute_template_non_interactive(template_path, env_vars, log)
              
              if template_result
                apply_msg = "✅ Template applied successfully"
                puts apply_msg
                log.puts apply_msg
              else
                error_msg = "❌ Template application failed"
                puts error_msg
                log.puts error_msg
                exit 1
              end
            else
              warning_msg = "⚠️  Not a Rails app, skipping template application"
              puts warning_msg
              log.puts warning_msg
            end
          end
          
          # Step 4: Compare the applied target with the templated version
          puts "\n4️⃣ Comparing applied target with templated version..."
          log.puts "4️⃣ Comparing applied target with templated version..."
          
          # Use git diff to compare directories
          diff_output = `diff -r --exclude='.git' --exclude='log' --exclude='tmp' --exclude='node_modules' --exclude='vendor/bundle' "#{target_test_path}" "#{templated_full_path}" 2>&1`
          diff_exit_code = $?.exitstatus
          
          # Save diff output
          File.write(diff_log, diff_output)
          
          # Analyze results
          if diff_exit_code == 0
            success_msg = "✅ SUCCESS: Target and templated versions are identical!"
            puts success_msg
            log.puts success_msg
            test_result = "PASSED"
          else
            warning_msg = "⚠️  DIFFERENCES FOUND: Target and templated versions differ"
            puts warning_msg
            log.puts warning_msg
            puts "📄 Differences saved to: #{diff_log}"
            log.puts "📄 Differences saved to: #{diff_log}"
            test_result = "FAILED"
            
            # Show summary of differences
            diff_lines = diff_output.lines
            file_diffs = diff_lines.select { |line| line.start_with?("Only in") || line.start_with?("Files") }.count
            puts "📊 Found #{file_diffs} file differences"
            log.puts "📊 Found #{file_diffs} file differences"
          end
          
          # Step 5: Create summary
          summary_content = <<~SUMMARY
            Git Template Target Comparison Summary
            =====================================
            Timestamp: #{Time.now}
            Target template: #{target_path}
            Templated version: #{templated_path}
            
            Results:
            • Test result: #{test_result}
            • Template application: #{template_result ? 'SUCCESS' : 'FAILED'}
            • Comparison: #{diff_exit_code == 0 ? 'IDENTICAL' : 'DIFFERENCES FOUND'}
            
            Log Files:
            • Main execution log: #{main_log}
            • Differences log: #{diff_log}
            • This summary: #{summary_log}
            
            Test Directory: #{test_dir}
          SUMMARY
          
          File.write(summary_log, summary_content)
          
          puts "\n📊 Summary:"
          puts "  • Test result: #{test_result}"
          puts "  • Template application: #{template_result ? 'SUCCESS' : 'FAILED'}"
          puts "  • Comparison: #{diff_exit_code == 0 ? 'IDENTICAL' : 'DIFFERENCES FOUND'}"
          puts ""
          puts "📁 Test directory: #{test_dir}"
          puts "📋 Logs saved to: #{log_dir}"
          puts "  • Main log: #{File.basename(main_log)}"
          puts "  • Differences: #{File.basename(diff_log)}"
          puts "  • Summary: #{File.basename(summary_log)}"
          puts ""
          
          if diff_exit_code == 0
            puts "🎉 Target comparison completed successfully!"
          else
            puts "⚠️  Target comparison found differences - review logs for details"
          end
          
        rescue => e
          error_msg = "❌ Error during target comparison: #{e.message}"
          puts error_msg
          log.puts error_msg
          log.puts "Backtrace:" if ENV["DEBUG"]
          log.puts e.backtrace.join("\n") if ENV["DEBUG"]
          puts e.backtrace if ENV["DEBUG"]
          exit 1
        end
      end
    rescue => e
      error_msg = "❌ Error during target comparison: #{e.message}"
      puts error_msg
      puts e.backtrace if ENV["DEBUG"]
      exit 1
    end

    def self.exit_on_failure?
      true
    end

    private

    def execute_template_non_interactive(template_path, env_vars, log)
      require "open3"
      require "pty"
      require "yaml"
      
      # Load template-specific responses
      auto_responses = load_template_responses(template_path, log)
      
      command = "bin/rails app:template LOCATION=#{template_path}"
      
      begin
        # Use PTY to handle interactive prompts
        success = false
        PTY.spawn(env_vars, command) do |stdout, stdin, pid|
          output_buffer = ""
          
          loop do
            begin
              # Read available output
              ready = IO.select([stdout], nil, nil, 1)
              if ready
                partial_output = stdout.read_nonblock(1024)
                output_buffer += partial_output
                print partial_output  # Show output in real-time
                
                # Check for prompts and respond automatically
                auto_responses.each do |pattern, response|
                  if output_buffer.match(pattern)
                    puts "\n🤖 Auto-responding: #{response.strip}"
                    log.puts "🤖 Auto-responding to prompt: #{pattern.source} -> #{response.strip}"
                    stdin.write(response)
                    stdin.flush
                    output_buffer = ""  # Clear buffer after responding
                    break
                  end
                end
              end
            rescue EOFError
              break
            rescue IO::WaitReadable
              # Continue if no data available
            end
          end
          
          # Wait for process to complete
          Process.wait(pid)
          success = $?.success?
          puts "\n🎯 Template execution completed with status: #{success}"
          log.puts "🎯 Template execution completed with status: #{success}"
        end
        return success
      rescue PTY::ChildExited => e
        puts "Template process exited: #{e.status}"
        log.puts "Template process exited: #{e.status}"
        e.status.success?
      rescue => e
        puts "Error executing template: #{e.message}"
        log.puts "Error executing template: #{e.message}"
        false
      end
    end

    def load_template_responses(template_path, log)
      # Default responses for common prompts
      default_responses = {
        # File overwrite prompts
        /Overwrite.*\? \(enter "h" for help\) \[Ynaqdhm\]/ => "y\n",
        /conflict.*Overwrite.*\[Ynaqdhm\]/ => "y\n",
        
        # Generic yes/no prompts (default to no for safety)
        /\? \(y\/n\)/ => "n\n",
        /\? \(yes\/no\)/ => "no\n"
      }
      
      # Try to load template-specific responses
      template_dir = File.dirname(template_path)
      config_file = File.join(template_dir, "test_responses.yml")
      
      if File.exist?(config_file)
        begin
          config = YAML.load_file(config_file)
          puts "📋 Loading template responses from: #{config_file}"
          log.puts "📋 Loading template responses from: #{config_file}"
          
          # Convert string patterns to regex and merge with defaults
          template_responses = {}
          config.each do |pattern_str, response|
            begin
              # Convert string to regex, handling both simple strings and regex patterns
              regex = if pattern_str.start_with?('/') && pattern_str.end_with?('/')
                # Handle regex format: "/pattern/flags"
                pattern_content = pattern_str[1..-2]  # Remove leading and trailing /
                Regexp.new(pattern_content, Regexp::IGNORECASE)
              else
                # Handle simple string patterns
                Regexp.new(Regexp.escape(pattern_str), Regexp::IGNORECASE)
              end
              
              # Ensure response ends with newline
              response_with_newline = response.to_s.end_with?("\n") ? response.to_s : "#{response}\n"
              template_responses[regex] = response_with_newline
              
              puts "  • #{pattern_str} → #{response.inspect}"
              log.puts "  • #{pattern_str} → #{response.inspect}"
            rescue => e
              puts "⚠️  Warning: Invalid pattern '#{pattern_str}': #{e.message}"
              log.puts "⚠️  Warning: Invalid pattern '#{pattern_str}': #{e.message}"
            end
          end
          
          # Merge template responses with defaults (template responses take precedence)
          default_responses.merge(template_responses)
        rescue => e
          puts "⚠️  Warning: Could not load #{config_file}: #{e.message}"
          log.puts "⚠️  Warning: Could not load #{config_file}: #{e.message}"
          default_responses
        end
      else
        puts "📋 Using default responses (no test_responses.yml found)"
        log.puts "📋 Using default responses (no test_responses.yml found)"
        default_responses
      end
    end

    private

    def setup_environment(options)
      ENV['VERBOSE'] = '1' if options[:verbose]
      ENV['DEBUG'] = '1' if options[:debug]
    end

    def handle_command_error(command_name, result)
      puts "❌ #{command_name.capitalize} command failed:"
      puts "   #{result[:error]}"
      
      if result[:error_type] && ENV['DEBUG']
        puts "   Error type: #{result[:error_type]}"
      end
      
      exit 1
    end

    def handle_unexpected_command_error(command_name, error, options)
      puts "❌ Unexpected error in #{command_name} command:"
      puts "   #{error.message}"
      
      if options[:debug] || ENV['DEBUG']
        puts "\nBacktrace:"
        puts error.backtrace.join("\n")
      else
        puts "\nRun with --debug for more details"
      end
      
      exit 1
    end

    def validate_command_prerequisites
      # Check if git is available
      unless system('git --version > /dev/null 2>&1')
        puts "❌ Error: git is not installed or not available in PATH"
        puts "   Please install git to use git-template commands"
        exit 1
      end
    end

    # Default action when no command is specified
    def self.start(args)
      if args.empty?
        puts "git-template - Rails application template with lifecycle management"
        puts ""
        puts "Usage:"
        puts "  git-template apply [PATH]     # Apply template to existing Rails app"
        puts "  git-template status FOLDER    # Check template development status"
        puts "  git-template clone GIT_URL    # Clone repository for template development"
        puts "  git-template iterate FOLDER   # Iterate and refine templates"
        puts "  git-template update FOLDER    # Update template configuration"
        puts "  git-template push FOLDER      # Push to remote repository"
        puts "  git-template version          # Show version"
        puts "  git-template list             # List available templates"
        puts "  git-template path             # Show template path"
        puts "  git-template help [COMMAND]   # Show help"
        puts ""
        puts "For new Rails applications:"
        puts "  rails new myapp -m git-template"
        puts ""
        return
      end
      
      super(args)
    end
  end
end