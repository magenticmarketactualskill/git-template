# TemplateLifecycle - Main orchestrator for Rails template creation
#
# This class provides a structured approach to managing Rails application template creation.
# It organizes template operations into phases, manages user configuration, handles dependencies,
# and provides clear execution feedback.

require_relative 'configuration_manager'
require_relative 'phase'
require_relative 'module_registry'
require_relative 'template_lifecycle_errors'

class TemplateLifecycle
  include TemplateLifecycleErrors
  attr_reader :template_context, :template_root, :configuration_manager, :module_registry, :execution_summary
  attr_accessor :phases

  def initialize(template_context, template_root: "template")
    @template_context = template_context
    @template_root = template_root
    @configuration_manager = ConfigurationManager.new(template_context)
    @module_registry = ModuleRegistry.new(template_root)
    @phases = []
    @execution_summary = {
      applied_modules: [],
      configuration: {},
      errors: [],
      start_time: nil,
      end_time: nil
    }
    
    initialize_default_phases
  end

  def execute
    @execution_summary[:start_time] = Time.now
    
    begin
      display_welcome_message
      configure_user_preferences
      load_available_components
      execute_phases
      display_completion_summary
    rescue => error
      handle_error(error)
      raise error
    ensure
      @execution_summary[:end_time] = Time.now
    end
    
    @execution_summary
  end

  def add_phase(phase)
    @phases << phase
    @phases.sort_by!(&:order)
  end

  def configure_user_preferences
    @configuration_manager.collect_preferences
    @execution_summary[:configuration] = @configuration_manager.to_hash
  end

  def current_configuration
    @configuration_manager
  end

  def template_root_path
    File.join(Dir.pwd, @template_root)
  end

  private

  def initialize_default_phases
    # Define the standard phases based on the folder structure mapping
    phase_definitions = {
      "platform" => { name: "Platform Setup", order: 1, description: "Ruby version, Rails configuration, database setup" },
      "infrastructure" => { name: "Infrastructure Setup", order: 2, description: "Gems, Redis, Solid Stack, deployment" },
      "frontend" => { name: "Frontend Setup", order: 3, description: "Vite, Tailwind, Inertia, Juris.js" },
      "testing" => { name: "Testing Setup", order: 4, description: "RSpec, Cucumber, testing frameworks" },
      "security" => { name: "Security Setup", order: 5, description: "Authorization, security gems" },
      "data_flow" => { name: "Data Flow Setup", order: 6, description: "ActiveDataFlow integration" },
      "application" => { name: "Application Features", order: 7, description: "Models, controllers, views, routes, admin" }
    }

    phase_definitions.each do |folder_name, definition|
      phase = Phase.new(
        definition[:name],
        definition[:description],
        order: definition[:order],
        folder_name: folder_name
      )
      add_phase(phase)
    end
  end

  def display_welcome_message
    @template_context.say "=" * 80
    @template_context.say "Rails 8 + Juris.js Application Template (TemplateLifecycle)"
    @template_context.say "=" * 80
    @template_context.say ""
    @template_context.say "This template will set up a Rails 8 application with organized phases:"
    
    @phases.each do |phase|
      @template_context.say "  • #{phase.name}: #{phase.description}"
    end
    
    @template_context.say ""
  end

  def load_available_components
    @module_registry.discover_modules
    
    # Auto-populate phases with discovered modules
    @phases.each do |phase|
      if phase.folder_name
        modules = @module_registry.get_modules_for_phase(phase.folder_name)
        modules.each do |module_path|
          # Use relative path from template root for cleaner display
          relative_path = module_path.sub(/^#{Regexp.escape(@template_root)}\//, '')
          phase.add_module(relative_path)
        end
      end
    end
  end

  def execute_phases
    @phases.each do |phase|
      next unless phase.should_execute?(@configuration_manager)
      
      @template_context.say "\n" + "=" * 80
      @template_context.say "#{phase.name}"
      @template_context.say "=" * 80 + "\n"
      
      begin
        executed_modules = phase.execute(@template_context, @configuration_manager)
        @execution_summary[:applied_modules].concat(executed_modules)
      rescue => error
        @execution_summary[:errors] << {
          phase: phase.name,
          error: error.message,
          backtrace: error.backtrace&.first(5)
        }
        
        # Continue with next phase unless it's a critical error
        @template_context.say "Warning: Phase '#{phase.name}' encountered an error: #{error.message}", :yellow
        @template_context.say "Continuing with remaining phases...", :yellow
      end
    end
  end

  def display_completion_summary
    @template_context.say "\n" + "=" * 80
    @template_context.say "Template Execution Complete!"
    @template_context.say "=" * 80 + "\n"
    
    @template_context.say "Applied Modules (#{@execution_summary[:applied_modules].length}):", :green
    @execution_summary[:applied_modules].each do |module_path|
      @template_context.say "  ✓ #{module_path}"
    end
    
    if @execution_summary[:errors].any?
      @template_context.say "\nWarnings/Errors (#{@execution_summary[:errors].length}):", :yellow
      @execution_summary[:errors].each do |error_info|
        @template_context.say "  ⚠ #{error_info[:phase]}: #{error_info[:error]}"
      end
    end
    
    execution_time = @execution_summary[:end_time] - @execution_summary[:start_time]
    @template_context.say "\nExecution completed in #{execution_time.round(2)} seconds", :green
  end

  def handle_error(error)
    @execution_summary[:errors] << {
      phase: "System",
      error: error.message,
      backtrace: error.backtrace&.first(10)
    }
    
    @template_context.say "\nCritical Error: #{error.message}", :red
    @template_context.say "Template execution failed. Please check the error details above.", :red
  end
end