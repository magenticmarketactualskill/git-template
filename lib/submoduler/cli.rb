# frozen_string_literal: true

require 'optparse'

module Submoduler
  class CLI
    COMMANDS = {
      'init' => 'Initialize submoduler in current repository',
      'validate' => 'Validate submoduler configuration',
      'status' => 'Show submodule status',
      'update' => 'Update submodules',
      'sync' => 'Synchronize with parent/children',
      'add' => 'Add a new submodule (parent mode)',
      'help' => 'Show help information'
    }.freeze
    
    def self.run(args)
      new(args).run
    end
    
    def initialize(args)
      @args = args.dup
      @command = nil
      @options = {}
    end
    
    def run
      if @args.empty?
        display_help
        return 0
      end

      @command = @args.shift

      case @command
      when 'help', '--help', '-h'
        display_help
        return 0
      when 'version', '--version', '-v'
        puts "submoduler #{Submoduler::VERSION}"
        return 0
      end

      unless COMMANDS.key?(@command)
        puts "Error: Unknown command '#{@command}'"
        display_help
        return 1
      end

      execute_command
    rescue AmbiguousContextError => e
      puts "Error: #{e.message}"
      1
    rescue ComponentLoadError => e
      puts "Error: #{e.message}"
      1
    rescue GitOperationError => e
      puts "Error: #{e.message}"
      1
    rescue StandardError => e
      puts "Error: #{e.message}"
      1
    end

    private

    def execute_command
      case @command
      when 'init'
        execute_init
      when 'validate'
        execute_validate
      when 'status'
        execute_status
      when 'update'
        execute_update
      when 'sync'
        execute_sync
      when 'add'
        execute_add
      else
        delegate_to_component
      end
    end
    
    def execute_init
      mode = nil
      
      OptionParser.new do |opts|
        opts.banner = "Usage: submoduler init [options]"
        
        opts.on('--mode MODE', [:parent, :child], 'Specify mode (parent or child)') do |m|
          mode = m
        end
        
        opts.on('-h', '--help', 'Display this help') do
          puts opts
          return 0
        end
      end.parse!(@args)
      
      operations = RepositoryOperations.new
      operations.initialize_repository(mode)
      0
    end
    
    def execute_validate
      operations = RepositoryOperations.new
      result = operations.validate_repository
      result ? 0 : 1
    end
    
    def execute_status
      begin
        mode = Submoduler.mode
        puts "Submoduler Status"
        puts "=================="
        puts "Mode: #{mode}"
        
        context = RepositoryContext.new
        puts "Repository: #{context.path}"
        
        case mode
        when :parent
          puts "Submodules: #{context.submodules.length}"
          context.submodules.each do |submodule|
            puts "  - #{submodule[:name]} (#{submodule[:path]})"
          end
        when :child
          puts "Parent: #{context.parent_path || 'Not detected'}"
        end
        
        0
      rescue AmbiguousContextError
        puts "Cannot determine repository mode. Run 'submoduler init' first."
        1
      end
    end
    
    def execute_update
      mode = Submoduler.mode
      
      case mode
      when :parent
        operations = RepositoryOperations.new
        operations.update_submodules
        0
      when :child
        operations = RepositoryOperations.new
        operations.sync_with_parent
        0
      else
        puts "Cannot determine mode. Run 'submoduler init' first."
        1
      end
    end
    
    def execute_sync
      # Alias for update
      execute_update
    end
    
    def execute_add
      if @args.length < 2
        puts "Usage: submoduler add <name> <url> [path]"
        return 1
      end
      
      name = @args[0]
      url = @args[1]
      path = @args[2]
      
      operations = RepositoryOperations.new
      operations.add_submodule(name, url, path)
      0
    end

    def delegate_to_component
      begin
        mode = Submoduler.mode
        component = ComponentManager.component_for_mode(mode)
        component.execute(@command, @args)
      rescue AmbiguousContextError
        puts "Cannot determine repository mode for command '#{@command}'"
        puts "Run 'submoduler init --mode <parent|child>' first."
        1
      end
    end

    def display_help
      puts "Submoduler - Unified submodule management"
      puts ""
      puts "Usage: submoduler <command> [options]"
      puts ""
      puts "Available commands:"
      
      # Show context-appropriate commands if we can detect mode
      begin
        mode = Submoduler.mode
        puts "  (#{mode} mode detected)"
        puts ""
        
        case mode
        when :parent
          display_parent_commands
        when :child
          display_child_commands
        end
      rescue AmbiguousContextError
        puts "  (no mode detected - run 'submoduler init' first)"
        puts ""
      end
      
      # Always show common commands
      COMMANDS.each do |cmd, desc|
        puts "  #{cmd.ljust(12)} #{desc}"
      end
      
      puts ""
      puts "Run 'submoduler <command> --help' for command-specific options"
    end
    
    def display_parent_commands
      puts "Parent mode commands:"
      puts "  add          Add a new submodule"
      puts "  update       Update all submodules"
      puts ""
    end
    
    def display_child_commands
      puts "Child mode commands:"
      puts "  sync         Sync with parent repository"
      puts ""
    end
  end
end