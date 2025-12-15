# frozen_string_literal: true

module Submoduler
  class Error < StandardError; end

  class AmbiguousContextError < Error
    def initialize(msg = "Cannot determine repository mode automatically")
      super("#{msg}\n\nTo resolve:\n" \
            "- Use 'submoduler init --mode parent' for parent repositories\n" \
            "- Use 'submoduler init --mode child' for child repositories\n" \
            "- Ensure .gitmodules exists for parent mode\n" \
            "- Ensure repository is a git submodule for child mode")
    end
  end

  class ComponentLoadError < Error
    def initialize(component)
      super("Failed to load #{component} component. " \
            "Ensure submoduler-#{component} gem is installed.")
    end
  end

  class GitOperationError < Error
    def initialize(operation, details)
      super("Git operation '#{operation}' failed: #{details}")
    end
  end

  class ConfigurationError < Error; end
end