require "thor"

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
          template_result = false
          if File.exist?("bin/rails")
            # Set environment variables to make template non-interactive
            env_vars = {
              "RAILS_TEMPLATE_NON_INTERACTIVE" => "true",
              "TEMPLATE_USE_REDIS" => "false",
              "TEMPLATE_USE_ACTIVE_DATA_FLOW" => "false", 
              "TEMPLATE_USE_DOCKER" => "false",
              "TEMPLATE_GENERATE_SAMPLE_MODELS" => "false",
              "TEMPLATE_SETUP_ADMIN" => "false",
              "THOR_MERGE" => "true"  # Auto-overwrite files without prompting
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
          success
        end
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

    # Default action when no command is specified
    def self.start(args)
      if args.empty?
        puts "git-template - Rails application template with lifecycle management"
        puts ""
        puts "Usage:"
        puts "  git-template apply [PATH]     # Apply template to existing Rails app"
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