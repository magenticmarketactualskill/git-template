# ReportResult Model
#
# This class represents the result of generating a formatted status report,
# containing both the structured data and formatted output.

require_relative 'base'

module GitTemplate
  module Models
    module Result
      class ReportResult < Base
        attr_reader :status_result, :formatted_report, :report_type

        def initialize(status_result, formatted_report, report_type = :detailed)
          super()
          @status_result = status_result
          @formatted_report = formatted_report
          @report_type = report_type
        end

        def summary
          {
            report_type: @report_type,
            folder_path: @status_result.folder_analysis.path,
            development_status: @status_result.development_status,
            report_length: @formatted_report.length,
            generated_at: @timestamp
          }
        end

        def to_s
          @formatted_report
        end

        def to_json
          @status_result.to_hash.merge({
            report_type: @report_type,
            generated_at: @timestamp
          })
        end
      end
    end
  end
end