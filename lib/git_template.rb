require_relative "git_template/version"
require_relative "git_template/template_resolver"
require_relative "git_template/gem_template_runner"

# Load existing TemplateLifecycle system
require_relative "template_lifecycle"
require_relative "configuration_manager"
require_relative "module_registry"
require_relative "phase"
require_relative "template_lifecycle_errors"

module GitTemplate
  class Error < StandardError; end
  
  # Main entry point for programmatic usage
  def self.apply_template(rails_app_generator, template_path = nil)
    runner = GemTemplateRunner.new(rails_app_generator)
    runner.run_template(template_path)
  end
  
  # Get the path to the bundled template
  def self.template_path
    TemplateResolver.gem_template_path
  end
end

# Load CLI after the base module is defined
require_relative "git_template/cli"