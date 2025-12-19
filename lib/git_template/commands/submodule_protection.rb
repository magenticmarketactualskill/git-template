# SubmoduleProtection Concern
#
# This module provides shared functionality for protecting submodule folders
# from being modified by commands that should only work on regular folders.

module GitTemplate
  module Command
    module SubmoduleProtection
      def is_submodule?(path)
        # Check if path is listed in .gitmodules
        return false unless File.exist?('.gitmodules')
        
        gitmodules_content = File.read('.gitmodules')
        # Look for a submodule section with this path
        match = gitmodules_content.match(/\[submodule\s+"[^"]*"\]\s*\n\s*path\s*=\s*#{Regexp.escape(path)}/m) ||
                gitmodules_content.match(/\[submodule\s+"[^"]*"\]\s*\n[^\[]*path\s*=\s*#{Regexp.escape(path)}/m)
        !match.nil?
      end
      
      def check_submodule_protection(path, command_name)
        if is_submodule?(path)
          Models::Result::IterateCommandResult.new(
            success: false,
            operation: command_name,
            error_message: "Cannot run #{command_name} on submodule '#{path}'. Use 'update-repo-template --path #{path}' instead."
          )
        else
          nil
        end
      end
    end
  end
end