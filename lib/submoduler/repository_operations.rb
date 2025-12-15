# frozen_string_literal: true

module Submoduler
  class RepositoryOperations
    def initialize(path = '.')
      @path = File.expand_path(path)
      @context = RepositoryContext.new(@path)
    end
    
    def initialize_repository(mode = nil)
      mode ||= detect_or_prompt_mode
      
      case mode
      when :parent
        initialize_parent_repository
      when :child
        initialize_child_repository
      else
        raise ArgumentError, "Invalid mode: #{mode}. Must be :parent or :child"
      end
    end
    
    def validate_repository
      case @context.mode
      when :parent
        validate_parent_repository
      when :child
        validate_child_repository
      else
        raise AmbiguousContextError
      end
    end
    
    def add_submodule(name, url, path = nil)
      raise GitOperationError.new('add_submodule', 'Not in parent mode') unless @context.parent?
      
      path ||= File.join('submodules', name)
      
      # Execute git submodule add command
      cmd = "git submodule add #{url} #{path}"
      result = execute_git_command(cmd)
      
      if result[:success]
        # Initialize submodule configuration
        submodule_path = File.join(@path, path)
        initialize_submodule_config(submodule_path, :child)
        
        puts "✓ Added submodule '#{name}' at #{path}"
        true
      else
        raise GitOperationError.new('add_submodule', result[:error])
      end
    end
    
    def update_submodules
      raise GitOperationError.new('update_submodules', 'Not in parent mode') unless @context.parent?
      
      cmd = 'git submodule update --init --recursive'
      result = execute_git_command(cmd)
      
      if result[:success]
        puts "✓ Updated all submodules"
        true
      else
        raise GitOperationError.new('update_submodules', result[:error])
      end
    end
    
    def sync_with_parent
      raise GitOperationError.new('sync_with_parent', 'Not in child mode') unless @context.child?
      
      # Pull latest changes from parent
      cmd = 'git pull origin main'
      result = execute_git_command(cmd)
      
      if result[:success]
        puts "✓ Synced with parent repository"
        true
      else
        raise GitOperationError.new('sync_with_parent', result[:error])
      end
    end
    
    private
    
    def detect_or_prompt_mode
      detector = ModeDetector.new(@path)
      
      begin
        detector.detect
      rescue AmbiguousContextError
        # If we can't detect automatically, default to parent mode
        # In a real CLI, this would prompt the user
        :parent
      end
    end
    
    def initialize_parent_repository
      # Create configuration
      config = Configuration.new
      config.mode = :parent
      config.save_to_file(File.join(@path, '.submoduler.ini'))
      
      # Create basic directory structure
      submodules_dir = File.join(@path, 'submodules')
      Dir.mkdir(submodules_dir) unless Dir.exist?(submodules_dir)
      
      # Create bin directory with scripts
      create_parent_scripts
      
      puts "✓ Initialized parent repository"
      true
    end
    
    def initialize_child_repository
      # Create configuration
      config = Configuration.new
      config.mode = :child
      config.save_to_file(File.join(@path, '.submoduler.ini'))
      
      # Create bin directory with scripts
      create_child_scripts
      
      puts "✓ Initialized child repository"
      true
    end
    
    def validate_parent_repository
      errors = []
      
      # Check for required files
      config_file = File.join(@path, '.submoduler.ini')
      errors << "Missing .submoduler.ini" unless File.exist?(config_file)
      
      # Check configuration
      if File.exist?(config_file)
        config = Configuration.load_from_file(config_file)
        errors << "Configuration not set to parent mode" unless config.parent_mode?
      end
      
      # Check for .gitmodules if submodules exist
      submodules_dir = File.join(@path, 'submodules')
      if Dir.exist?(submodules_dir) && !Dir.empty?(submodules_dir)
        gitmodules = File.join(@path, '.gitmodules')
        errors << "Missing .gitmodules file" unless File.exist?(gitmodules)
      end
      
      if errors.empty?
        puts "✓ Parent repository validation passed"
        true
      else
        puts "✗ Parent repository validation failed:"
        errors.each { |error| puts "  - #{error}" }
        false
      end
    end
    
    def validate_child_repository
      errors = []
      
      # Check for required files
      config_file = File.join(@path, '.submoduler.ini')
      errors << "Missing .submoduler.ini" unless File.exist?(config_file)
      
      # Check configuration
      if File.exist?(config_file)
        config = Configuration.load_from_file(config_file)
        errors << "Configuration not set to child mode" unless config.child_mode?
      end
      
      # Check if this is actually a submodule
      unless @context.child?
        errors << "Repository is not configured as a git submodule"
      end
      
      if errors.empty?
        puts "✓ Child repository validation passed"
        true
      else
        puts "✗ Child repository validation failed:"
        errors.each { |error| puts "  - #{error}" }
        false
      end
    end
    
    def initialize_submodule_config(submodule_path, mode)
      config = Configuration.new
      config.mode = mode
      config.save_to_file(File.join(submodule_path, '.submoduler.ini'))
    end
    
    def create_parent_scripts
      bin_dir = File.join(@path, 'bin')
      Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
      
      # Create a simple Gemfile template
      gemfile_template = File.join(bin_dir, 'Gemfile.erb')
      File.write(gemfile_template, <<~ERB)
        # frozen_string_literal: true
        
        source 'https://rubygems.org'
        
        gem 'submoduler'
        
        # Add your gem dependencies here
      ERB
    end
    
    def create_child_scripts
      bin_dir = File.join(@path, 'bin')
      Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
      
      # Create a simple Gemfile template
      gemfile_template = File.join(bin_dir, 'Gemfile.erb')
      File.write(gemfile_template, <<~ERB)
        # frozen_string_literal: true
        
        source 'https://rubygems.org'
        
        gem 'submoduler'
        
        # Add your gem dependencies here
      ERB
    end
    
    def execute_git_command(command)
      output = `#{command} 2>&1`
      success = $?.success?
      
      {
        success: success,
        output: output,
        error: success ? nil : output
      }
    end
  end
end