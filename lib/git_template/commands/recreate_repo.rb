# RecreateRepoCommand Concern
#
# This command performs a full repository iteration, recreating the templated folder
# from scratch and comparing it with the source application folder.

require_relative 'base'
require_relative '../services/template_iteration'
require_relative '../status_command_errors'

module GitTemplate
  module Command
    module RecreateRepo
      def self.included(base)
        base.class_eval do
          desc "recreate-repo [URL]", "Recreate repo creates a submodule with a git clone of the repo, creates a templated folder, and recreates the repo using the .git-template folder. It then does a comparison of the generated content with the original"
          add_common_options
          option :clean_before, type: :boolean, default: true, desc: "Clean templated folder before recreation"
          option :detailed_comparison, type: :boolean, default: true, desc: "Generate detailed comparison report"
          
          define_method :recreate_repo do |path = "."|
          end
        end
      end
    end
  end
end