# Phase - Represents a logical grouping of related template modules
#
# This class groups related template modules within phase-specific folders,
# manages execution conditions and dependencies, executes all modules within
# the phase, and provides progress feedback during execution.

class Phase
  attr_reader :name, :description, :order, :folder_name, :modules, :dependencies

  def initialize(name, description, order: 0, folder_name: nil)
    @name = name
    @description = description
    @order = order
    @folder_name = folder_name
    @modules = []
    @dependencies = []
  end

  def add_module(module_path, conditions: nil, dependencies: [])
    module_info = {
      path: module_path,
      conditions: conditions || {},
      dependencies: dependencies || []
    }
    @modules << module_info
  end

  def execute(template_context, configuration_manager)
    executed_modules = []
    
    return executed_modules unless should_execute?(configuration_manager)
    
    template_context.say "Executing #{@name} phase...", :green
    
    @modules.each do |module_info|
      next unless should_execute_module?(module_info, configuration_manager)
      
      begin
        execute_module(module_info, template_context, configuration_manager)
        executed_modules << module_info[:path]
        template_context.say "✓ Applied #{File.basename(module_info[:path])}", :green
      rescue => error
        template_context.say "✗ Failed to apply #{File.basename(module_info[:path])}: #{error.message}", :red
        raise error if critical_module?(module_info)
        # Continue with non-critical modules
      end
    end
    
    executed_modules
  end

  def should_execute?(configuration_manager)
    # Check if phase dependencies are satisfied
    return false unless dependencies_satisfied?(configuration_manager)
    
    # Check if any modules in this phase should execute
    @modules.any? { |module_info| should_execute_module?(module_info, configuration_manager) }
  end

  def dependencies_satisfied?(configuration_manager)
    @dependencies.all? do |dependency|
      case dependency[:type]
      when :configuration
        configuration_manager.get(dependency[:key]) == dependency[:value]
      when :phase
        # For now, assume phase dependencies are handled by execution order
        true
      else
        true
      end
    end
  end

  def folder_path
    @folder_name
  end

  def add_dependency(type:, key: nil, value: nil, phase: nil)
    dependency = { type: type }
    dependency[:key] = key if key
    dependency[:value] = value if value
    dependency[:phase] = phase if phase
    
    @dependencies << dependency
  end

  private

  def should_execute_module?(module_info, configuration_manager)
    conditions = module_info[:conditions]
    return true if conditions.empty?
    
    conditions.all? do |key, expected_value|
      actual_value = configuration_manager.get(key)
      actual_value == expected_value
    end
  end

  def execute_module(module_info, template_context, configuration_manager)
    module_path = resolve_module_path(module_info[:path])
    
    unless File.exist?(module_path)
      raise ModuleNotFoundError, "Module not found: #{module_path}"
    end
    
    # Make configuration available to the module
    # Store current configuration in instance variables for module access
    configuration_manager.to_hash.each do |key, value|
      instance_var_name = "@#{key}"
      template_context.instance_variable_set(instance_var_name, value)
    end
    
    # Execute the module using Rails template apply method
    template_context.apply(module_path)
  end

  def resolve_module_path(module_path)
    # If it's already an absolute path, use it
    return module_path if File.absolute_path?(module_path)
    
    # If it's relative and we have a folder_name, construct the path
    if @folder_name && !module_path.include?('/')
      File.join("template", @folder_name, module_path)
    else
      module_path
    end
  end

  def critical_module?(module_info)
    # For now, consider all modules non-critical to allow graceful degradation
    # This can be made configurable in the future
    false
  end

  class ModuleNotFoundError < StandardError; end
end