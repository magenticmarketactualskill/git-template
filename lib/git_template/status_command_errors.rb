# Status Command Error Classes
#
# This module provides error classes specific to the status command system
# for handling various failure scenarios in template lifecycle management.

module GitTemplate
  module StatusCommandErrors
    class StatusCommandError < GitTemplate::Error
      def initialize(message)
        super(message)
      end
    end

    class InvalidPathError < StatusCommandError
      def initialize(path)
        super("Invalid or inaccessible path: #{path}")
      end
    end

    class GitOperationError < StatusCommandError
      def initialize(operation, details)
        super("Git operation '#{operation}' failed: #{details}")
      end
    end

    class TemplateValidationError < StatusCommandError
      def initialize(template_path, issues)
        super("Template validation failed for #{template_path}: #{issues.join(', ')}")
      end
    end

    class FolderAnalysisError < StatusCommandError
      def initialize(path, reason)
        super("Failed to analyze folder #{path}: #{reason}")
      end
    end

    class TemplateProcessingError < StatusCommandError
      def initialize(operation, details)
        super("Template processing error during #{operation}: #{details}")
      end
    end
  end
end