# StatusFormatter Service
#
# This service handles formatting of status information for different output formats.
# It provides methods to format status summaries in a consistent and readable way.

module GitTemplate
  module Services
    class StatusFormatter
      def initialize
      end

      # Formats a status summary result into a human-readable string format
      #
      # @param result [Hash] The result hash containing summary data
      # @return [String] Formatted status output
      def format_summary_status(result)
        summary = result[:summary]
        output = []
        
        output << "Folder: #{summary[:folder]}"
        output << "Status: #{summary[:status]}"
        output << "Exists: #{summary[:exists] ? '✅' : '❌'}"
        output << "Git repository: #{summary[:git_repository] ? '✅' : '❌'}"
        output << "Template configuration: #{summary[:template_configuration] ? '✅' : '❌'}"
        output << "Templated folder: #{summary[:templated_folder] ? '✅' : '❌'}"
        output << "Ready for iteration: #{summary[:ready_for_iteration] ? '✅' : '❌'}"
        
        output.join("\n")
      end
    end
  end
end