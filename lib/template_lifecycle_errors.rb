# TemplateLifecycle Error Classes
#
# This file defines custom error classes for the TemplateLifecycle system
# to provide meaningful error messages and enable proper error handling.

module TemplateLifecycleErrors
  class TemplateLifecycleError < StandardError; end
  
  class ConfigurationError < TemplateLifecycleError; end
  
  class ModuleNotFoundError < TemplateLifecycleError; end
  
  class DependencyError < TemplateLifecycleError; end
  
  class PhaseExecutionError < TemplateLifecycleError
    attr_reader :phase_name, :original_error
    
    def initialize(phase_name, original_error)
      @phase_name = phase_name
      @original_error = original_error
      super("Phase '#{phase_name}' failed: #{original_error.message}")
    end
  end
  
  class ModuleExecutionError < TemplateLifecycleError
    attr_reader :module_path, :original_error
    
    def initialize(module_path, original_error)
      @module_path = module_path
      @original_error = original_error
      super("Module '#{module_path}' failed: #{original_error.message}")
    end
  end
  
  class TemplateFolderNotFoundError < TemplateLifecycleError; end
end