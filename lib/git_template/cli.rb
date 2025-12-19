require "thor"
require "fileutils"
require_relative "commands/base"
require_relative "commands/compare"
require_relative "commands/clone"
require_relative "commands/status"
require_relative "commands/iterate"
require_relative "commands/push"
require_relative "commands/create_templated_folder"
require_relative "commands/rerun_template"
require_relative "commands/recreate_repo"
require_relative "commands/remove_repo"
require_relative "commands/create_templated_folder_public"
require_relative "commands/regenerate_template"
require_relative "commands/update_repo_template"

module GitTemplate
  class CLI < Thor
    include GitTemplate::Command::Base
    include GitTemplate::Command::CreateTemplatedFolder
    include GitTemplate::Command::Compare
    include GitTemplate::Command::Clone
    include GitTemplate::Command::Status
    include GitTemplate::Command::Iterate
    include GitTemplate::Command::Push
    include GitTemplate::Command::RerunTemplate
    include GitTemplate::Command::RecreateRepo
    include GitTemplate::Command::RemoveRepo
    include GitTemplate::Command::MethodVisibilityFix
    include GitTemplate::Command::RegenerateTemplate
    include GitTemplate::Command::UpdateRepoTemplate
    
    def initialize(*args)
      super
      @logger = setup_logger
    end
  end
end