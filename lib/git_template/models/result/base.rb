# Base Result Model
#
# This class provides common functionality for all result models
# in the GitTemplate system.

require_relative '../../status_command_errors'

module GitTemplate
  module Models
    module Result
      class Base
        include StatusCommandErrors

        attr_reader :timestamp

        def initialize
          @timestamp = Time.now
        end

        # Common interface methods that subclasses should implement
        def summary
          raise NotImplementedError, "Subclasses must implement #summary"
        end

        protected

        # Common utility methods for result classes
        def expand_path(path)
          File.expand_path(path)
        end

        def current_time
          Time.now
        end
      end
    end
  end
end