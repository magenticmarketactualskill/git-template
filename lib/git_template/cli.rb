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
      
      templated_app_path = options[:templated_app_path]
      
      puts "🧪 Starting git-template test..."
      puts "Templated app path: #{templated_app_path}"
      
      # Step 1: Confirm .git_template path exists
      git_template_root = File.expand_path("../..", __dir__)
      puts "\n1️⃣ Checking .git_template path..."
      puts "Git template root: #{git_template_root}"
      
      unless File.directory?(git_template_root)
        puts "❌ Error: .git_template path does not exist: #{git_template_root}"
        exit 1
      end
      puts "✅ .git_template path exists"
      
      # Step 2: Validate .git_template contents
      puts "\n2️⃣ Validating .git_template contents..."
      required_paths = [
        "lib/git_template.rb",
        "template",
        templated_app_path
      ]
      
      required_paths.each do |path|
        full_path = File.join(git_template_root, path)
        unless File.exist?(full_path)
          puts "❌ Error: Required path missing: #{path}"
          exit 1
        end
        puts "✅ Found: #{path}"
      end
      
      # Step 3: Create folder template_test
      puts "\n3️⃣ Creating template_test folder..."
      test_dir = File.join(Dir.pwd, "template_test")
      
      if File.exist?(test_dir)
        puts "🗑️  Removing existing template_test directory..."
        FileUtils.rm_rf(test_dir)
      end
      
      FileUtils.mkdir_p(test_dir)
      puts "✅ Created: #{test_dir}"
      
      # Step 4: Copy JUST the template folder to template_test/[templated_app_path]
      puts "\n4️⃣ Copying template to test directory..."
      source_path = File.join(git_template_root, templated_app_path)
      dest_path = File.join(test_dir, templated_app_path)
      
      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.cp_r(source_path, dest_path)
      puts "✅ Copied #{templated_app_path} to #{dest_path}"
      
      # Step 5: Clean up files to remove problematic references
      puts "\n5️⃣ Cleaning up files for testing..."
      
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
        puts "✅ Cleaned up Gemfile"
      end
      
      # Clean up boot.rb
      boot_path = File.join(dest_path, "config", "boot.rb")
      if File.exist?(boot_path)
        boot_content = File.read(boot_path)
        boot_content.gsub!(/^require\s+['"]active_data_flow['"].*$/, "# require 'active_data_flow' # Commented out for testing")
        File.write(boot_path, boot_content)
        puts "✅ Cleaned up boot.rb"
      end
      
      # Clean up or remove ActiveDataFlow initializer
      initializer_path = File.join(dest_path, "config", "initializers", "active_data_flow.rb")
      if File.exist?(initializer_path)
        File.delete(initializer_path)
        puts "✅ Removed ActiveDataFlow initializer"
      end
      
      # Step 6: Run the template and capture git diff
      puts "\n6️⃣ Running git-template and capturing changes..."
      
      Dir.chdir(dest_path) do
        # Initialize git repo if not exists
        unless File.directory?(".git")
          puts "📝 Initializing git repository..."
          system("git init", out: File::NULL, err: File::NULL)
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Initial commit before template'", out: File::NULL, err: File::NULL)
        end
        
        # Install gems first
        puts "📦 Installing gems..."
        system("bundle install")
        
        # Apply the template
        # First check if there's a local .git_template/template.rb
        local_template_path = File.join(Dir.pwd, ".git_template", "template.rb")
        template_path = if File.exist?(local_template_path)
          local_template_path
        else
          File.join(git_template_root, "template.rb")
        end
        
        puts "🔧 Applying template: #{template_path}"
        
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
            "THOR_MERGE" => "true"  # Auto-overwrite files without prompting
          }
          
          puts "Environment variables:"
          env_vars.each { |k, v| puts "  #{k}=#{v}" }
          puts ""
          
          result = system(env_vars, "bin/rails app:template LOCATION=#{template_path}")
          puts "Template execution result: #{result}"
        else
          puts "⚠️  Warning: Not a Rails app, skipping template application"
        end
        
        # Capture git diff
        puts "\n📊 Git diff output (file by file, line by line):"
        puts "=" * 80
        
        # Show status first
        puts "📋 Git Status:"
        system("git status --porcelain")
        puts "\n" + "=" * 80
        
        # Show detailed diff
        puts "📝 Detailed Changes:"
        system("git add .")
        system("git diff --cached --no-color")
        
        puts "=" * 80
        puts "✅ Template test completed!"
        puts ""
        puts "📊 Summary:"
        
        # Count changes
        status_output = `git status --porcelain`
        modified_files = status_output.lines.select { |line| line.start_with?(' M') }.count
        new_files = status_output.lines.select { |line| line.start_with?('??') }.count
        
        puts "  • #{modified_files} files modified"
        puts "  • #{new_files} new files created"
        puts "  • Template execution: #{result ? 'SUCCESS' : 'PARTIAL (with errors)'}"
        puts ""
        puts "📁 Test results available in: #{dest_path}"
      end
      
    rescue => e
      puts "❌ Error during template test: #{e.message}"
      puts e.backtrace if ENV["DEBUG"]
      exit 1
    end

    def self.exit_on_failure?
      true
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