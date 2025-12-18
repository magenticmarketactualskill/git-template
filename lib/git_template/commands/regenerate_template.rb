# RegenerateTemplate Concern
#
# This command deletes the template.rb file in the templated directory
# and then runs the template generators to recreate it from scratch.

require_relative 'base'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'
require 'fileutils'

module GitTemplate
  module Command
    module RegenerateTemplate
      def self.included(base)
        base.class_eval do
          desc "regenerate-template", "Delete template.rb and regenerate it using template generators"
          add_common_options
          option :path, type: :string, default: ".", desc: "Templated folder path (defaults to current directory)"
          option :backup, type: :boolean, default: true, desc: "Create backup of existing template.rb before deletion"
          
          define_method :regenerate_template do
            execute_with_error_handling("regenerate_template", options) do
              path = options[:path] || "."
              log_command_execution("regenerate_template", [path], options)
              setup_environment(options)
              
              # Validate templated folder
              validated_path = validate_directory_path(path, must_exist: true)
              
              # Check if this is a templated folder with .git_template
              git_template_dir = File.join(validated_path, '.git_template')
              unless File.directory?(git_template_dir)
                result = Models::Result::IterateCommandResult.new(
                  success: false,
                  operation: "regenerate_template",
                  error_message: "No .git_template directory found at #{validated_path}. This doesn't appear to be a templated folder."
                )
                puts result.format_output(options[:format], options)
                return result
              end
              
              # Check if template.rb exists
              template_file = File.join(git_template_dir, 'template.rb')
              template_exists = File.exist?(template_file)
              
              # Create backup if requested and template exists
              backup_file = nil
              if template_exists && options[:backup]
                timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
                backup_file = "#{template_file}.backup_#{timestamp}"
                FileUtils.cp(template_file, backup_file)
              end
              
              # Delete existing template.rb if it exists
              if template_exists
                File.delete(template_file)
              end
              
              # Regenerate template.rb using generators
              result = regenerate_template_file(git_template_dir, validated_path, options)
              
              # Add backup info to result if backup was created
              if backup_file
                result.data[:backup_file] = backup_file
              end
              
              # Output result
              puts result.format_output(options[:format], options)
              result
            end
          end
          
          private
          
          define_method :regenerate_template_file do |git_template_dir, templated_path, options|
            begin
              template_file = File.join(git_template_dir, 'template.rb')
              
              # Load available generators
              generators = load_template_generators
              
              # Generate new template.rb content
              template_content = generate_template_content(generators, templated_path)
              
              # Write new template.rb file
              File.write(template_file, template_content)
              
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "regenerate_template",
                data: {
                  template_file: template_file,
                  templated_path: templated_path,
                  generators_used: generators.map { |g| g[:name] },
                  regenerated_at: Time.now
                }
              )
            rescue => e
              Models::Result::IterateCommandResult.new(
                success: false,
                operation: "regenerate_template",
                error_message: "Template regeneration failed: #{e.message}"
              )
            end
          end
          
          define_method :load_template_generators do
            generators = []
            generator_dir = File.join(File.dirname(__FILE__), '..', 'generator')
            
            # Define the standard generator order and their details
            generator_configs = [
              { file: 'gem_bundle.rb', class: 'GemBundle', name: 'GemBundleGenerator', phase: '030_PHASE_GemBundle' },
              { file: 'view.rb', class: 'View', name: 'ViewGenerator', phase: '040_PHASE_View' },
              { file: 'test.rb', class: 'Test', name: 'TestGenerator', phase: '050_PHASE_Test' },
              { file: 'home_feature.rb', class: 'HomeFeature', name: 'HomeFeatureGenerator', phase: '100_PHASE_Feature_Home' },
              { file: 'post_feature.rb', class: 'PostFeature', name: 'PostFeatureGenerator', phase: '100_PHASE_Feature_Post' },
              { file: 'completion.rb', class: 'Completion', name: 'CompletionGenerator', phase: '900_PHASE_Complete' }
            ]
            
            generator_configs.each do |config|
              generator_file = File.join(generator_dir, config[:file])
              if File.exist?(generator_file)
                generators << {
                  name: config[:name],
                  class_name: config[:class],
                  phase: config[:phase],
                  file_path: generator_file
                }
              end
            end
            
            generators
          end
          
          define_method :generate_template_content do |generators, templated_path|
            content = []
            
            # Header
            content << "# Rails Template"
            content << "# Generated by git-template regenerate-template command"
            content << "# Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            content << ""
            content << "# Load generator modules"
            
            # Add require statements for generators
            generators.each do |generator|
              relative_path = "../../../lib/git_template/generator/#{File.basename(generator[:file_path])}"
              content << "require_relative '#{relative_path}'"
            end
            
            content << ""
            content << "say \"Applying template...\""
            content << ""
            
            # Add Ruby version phase
            content << "#~ 010_PHASE_RubyVersion"
            content << "# Ruby version configuration (handled by Rails application setup)"
            content << ""
            
            # Generate content for each generator
            generators.each do |generator|
              content << "#~ #{generator[:phase]}"
              content << "# Module Usage: GitTemplate::Generators::#{generator[:class_name]}"
              content << "# Method: execute()"
              content << ""
              content << "say \"#~ #{generator[:phase]}\""
              content << "GitTemplate::Generators::#{generator[:class_name]}.execute"
              content << ""
            end
            
            # Footer
            content << "say \"Template application completed!\", :green"
            
            content.join("\n")
          end
        end
      end
    end
  end
end