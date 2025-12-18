# FolderAnalysis Model
#
# This class represents the analysis results of a folder, including
# its git repository status, template configuration presence, and
# related templated folder information.

require 'fileutils'
require_relative '../../status_command_errors'
require_relative '../templater_folder'

module GitTemplate
  module Models
    module Result
      class FolderAnalysis
      include StatusCommandErrors

      attr_reader :path, :exists, :is_git_repository, :has_template_configuration,
                  :templated_folder_path, :templated_folder_exists, 
                  :templated_has_configuration, :analysis_timestamp, :templater_folder

      def initialize(path)
        @path = File.expand_path(path)
        @analysis_timestamp = Time.now
        @templater_folder = TemplaterFolder.new(path)
        analyze
      end

      def status_summary
        base_summary = @templater_folder.status_summary
        base_summary[:analysis_timestamp] = @analysis_timestamp
        base_summary
      end

      def valid_application_folder?
        @templater_folder.valid_application_folder?
      end

      def ready_for_iteration?
        @templater_folder.ready_for_iteration?
      end

      private

      def analyze
        begin
          @exists = @templater_folder.exists?
          @is_git_repository = @templater_folder.git_repository?
          @has_template_configuration = @templater_folder.has_template_configuration?
          @templated_folder_path = @templater_folder.templated_folder_path
          @templated_folder_exists = @templater_folder.templated_folder_exists?
          @templated_has_configuration = @templater_folder.templated_folder&.has_template_configuration? || false
        rescue => e
          raise FolderAnalysisError.new(@path, e.message)
        end
      end
      end
    end
  end
end