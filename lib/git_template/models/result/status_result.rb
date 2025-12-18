# StatusResult Model
#
# This class represents the result of a comprehensive status analysis,
# including folder analysis, development status, and recommendations.

require_relative 'base'
require_relative 'folder_analysis'

module GitTemplate
  module Models
    module Result
      class StatusResult < Base
        attr_reader :folder_analysis, :development_status, :recommendations,
                    :template_configuration, :templated_folder_analysis,
                    :templated_template_configuration

        def initialize(folder_analysis, development_status, recommendations = [])
          super()
          @folder_analysis = folder_analysis
          @development_status = development_status
          @recommendations = recommendations
          @template_configuration = nil
          @templated_folder_analysis = nil
          @templated_template_configuration = nil
        end

        def add_template_configuration(config)
          @template_configuration = config
        end

        def add_templated_folder_analysis(analysis)
          @templated_folder_analysis = analysis
        end

        def add_templated_template_configuration(config)
          @templated_template_configuration = config
        end

        def summary
          {
            folder_path: @folder_analysis.path,
            development_status: @development_status,
            exists: @folder_analysis.exists,
            is_git_repository: @folder_analysis.is_git_repository,
            has_template_configuration: @folder_analysis.has_template_configuration,
            templated_folder_exists: @folder_analysis.templated_folder_exists,
            ready_for_iteration: @folder_analysis.ready_for_iteration?,
            recommendations_count: @recommendations.length,
            analysis_timestamp: @folder_analysis.analysis_timestamp
          }
        end

        def has_template_issues?
          return false unless @template_configuration
          !@template_configuration[:valid]
        end

        def has_templated_issues?
          return false unless @templated_template_configuration
          !@templated_template_configuration[:valid]
        end

        def ready_for_iteration?
          @development_status == :ready_for_template_iteration
        end

        def needs_setup?
          [:folder_not_found, :not_template_project].include?(@development_status)
        end

        def to_hash
          {
            folder_analysis: @folder_analysis.status_summary,
            development_status: @development_status,
            recommendations: @recommendations,
            template_configuration: @template_configuration,
            templated_folder_analysis: @templated_folder_analysis&.status_summary,
            templated_template_configuration: @templated_template_configuration,
            timestamp: @timestamp
          }
        end
      end
    end
  end
end