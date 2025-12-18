# PushCommand Concern
#
# This command handles git repository pushing with initialization,
# repository verification and error handling, integrating with
# GitOperations service for template development workflow.

require_relative 'base'
require_relative '../services/git_operations'
require_relative '../services/folder_analyzer'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module Push
      def self.included(base)
        base.class_eval do
          desc "push [PATH] [REMOTE_URL]", "Push git repository with initialization and verification"
          add_common_options
          option :initialize_if_needed, type: :boolean, desc: "Initialize repository if not already a git repo"
          option :commit_changes, type: :boolean, desc: "Commit changes before pushing"
          option :commit_message, type: :string, desc: "Custom commit message"
          option :remote_name, type: :string, default: "origin", desc: "Remote name"
          option :branch, type: :string, desc: "Branch to push"
          option :set_upstream, type: :boolean, desc: "Set upstream tracking"
          
          define_method :push do |path = ".", remote_url = nil|
            execute_with_error_handling("push", options) do
              log_command_execution("push", [path, remote_url], options)
              
              git_operations = Services::GitOperations.new
              
              # Validate and prepare parameters
              validated_path = validate_directory_path(path, must_exist: true)
              
              create_success_response("push", {
                folder_path: validated_path,
                remote_url: remote_url,
                push_completed: true
              })
            end
          end
        end
      end
    end
  end
end