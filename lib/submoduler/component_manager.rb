# frozen_string_literal: true

module Submoduler
  class ComponentManager
    def self.parent_component
      @parent_component ||= ParentComponent.new
    end
    
    def self.child_component
      @child_component ||= ChildComponent.new
    end
    
    def self.component_for_mode(mode)
      case mode
      when :parent
        parent_component
      when :child
        child_component
      else
        raise ComponentLoadError.new("unknown mode: #{mode}")
      end
    end
  end

  class ParentComponent
    def initialize
      load_component_gem
    end
    
    def execute(command, args)
      # Use our new repository operations for parent functionality
      case command
      when 'init'
        init_parent_mode(args)
      when 'validate'
        validate_parent_mode(args)
      else
        puts "Parent mode command '#{command}' not yet implemented"
        1
      end
    rescue => e
      raise ComponentLoadError.new("submoduler_parent: #{e.message}")
    end
    
    def available?
      load_component_gem
      true
    rescue LoadError
      false
    end
    
    private
    
    def load_component_gem
      # Try to load the component gem first
      begin
        require 'submoduler/submoduler_parent'
      rescue LoadError
        # Component gem not available, use built-in functionality
      end
    end
    
    def init_parent_mode(args)
      puts "Initializing parent mode..."
      
      operations = RepositoryOperations.new
      operations.initialize_repository(:parent)
      0
    end
    
    def validate_parent_mode(args)
      puts "Validating parent mode configuration..."
      
      operations = RepositoryOperations.new
      result = operations.validate_repository
      result ? 0 : 1
    end
  end

  class ChildComponent
    def initialize
      load_component_gem
    end
    
    def execute(command, args)
      # For now, provide basic child functionality
      # This will be expanded as we integrate the actual child gem
      case command
      when 'init'
        init_child_mode(args)
      when 'validate'
        validate_child_mode(args)
      when 'status'
        status_child_mode(args)
      else
        puts "Child mode command '#{command}' not yet implemented"
        1
      end
    rescue LoadError => e
      raise ComponentLoadError.new("submoduler_child: #{e.message}")
    end
    
    def available?
      load_component_gem
      true
    rescue LoadError
      false
    end
    
    private
    
    def load_component_gem
      # Try to load the component gem first
      begin
        require 'submoduler/submoduler_child'
      rescue LoadError
        # For now, we'll implement basic child functionality locally
        # This will be replaced with actual gem integration
      end
    end
    
    def init_child_mode(args)
      puts "Initializing child mode..."
      
      config = Configuration.new
      config.mode = :child
      config.save_to_file
      
      puts "✓ Child mode initialized"
      0
    end
    
    def validate_child_mode(args)
      puts "Validating child mode configuration..."
      
      unless File.exist?('.submoduler.ini')
        puts "✗ Missing .submoduler.ini configuration file"
        return 1
      end
      
      config = Configuration.load_from_file
      unless config.child_mode?
        puts "✗ Configuration not set for child mode"
        return 1
      end
      
      puts "✓ Child mode configuration valid"
      0
    end
    
    def status_child_mode(args)
      puts "Child repository status:"
      
      context = RepositoryContext.new
      puts "  Mode: #{context.mode}"
      puts "  Path: #{context.path}"
      puts "  Parent: #{context.parent_path || 'Not detected'}"
      
      0
    end
  end
end