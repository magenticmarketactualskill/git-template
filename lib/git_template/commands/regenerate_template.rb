# RegenerateTemplate Concern
#
# This command deletes the template.rb file in the templated directory
# and then runs the template generators to recreate it from scratch.

require_relative 'base'
require_relative 'submodule_protection'
require_relative '../models/result/iterate_command_result'
require_relative '../status_command_errors'
require 'fileutils'

module GitTemplate
  module Command
    module RegenerateTemplate
      def self.included(base)
        base.class_eval do
          include SubmoduleProtection
          desc "regenerate-template", "Delete template.rb and regenerate it using template generators"
          add_common_options
          option :path, type: :string, default: ".", desc: "Templated folder path (defaults to current directory)"
          option :backup, type: :boolean, default: true, desc: "Create backup of existing template.rb before deletion"
          
          define_method :regenerate_template do
            execute_with_error_handling("regenerate_template", options) do
              path = options[:path] || "."
              log_command_execution("regenerate_template", [path], options)
              setup_environment(options)
              
              # Check if path is a submodule - if so, reject the operation
              protection_result = check_submodule_protection(path, "regenerate_template")
              if protection_result
                puts protection_result.format_output(options[:format], options)
                return protection_result
              end
              
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
              
              # Show detailed output of the regenerated template
              show_regenerated_template_details(result.data[:template_file], result.data[:generators_full], options)
              
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
              
              # Generate/update template.rb.md documentation file
              md_file = File.join(git_template_dir, 'template.rb.md')
              md_content = generate_template_documentation(generators, templated_path)
              File.write(md_file, md_content)
              
              Models::Result::IterateCommandResult.new(
                success: true,
                operation: "regenerate_template",
                data: {
                  template_file: template_file,
                  documentation_file: md_file,
                  templated_path: templated_path,
                  generators_used: generators.map { |g| g[:name] },
                  generators_full: generators,
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
          
          define_method :generate_template_documentation do |generators, templated_path|
            content = []
            
            # Header
            content << "# Rails Template Documentation"
            content << ""
            content << "Generated by git-template regenerate-template command"
            content << "Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            content << ""
            content << "## Template Overview"
            content << ""
            content << "This template uses modular generators for clean, maintainable code:"
            content << ""
            content << "```ruby"
            content << "# Load generator modules"
            generators.each do |generator|
              relative_path = "../../../lib/git_template/generator/#{File.basename(generator[:file_path])}"
              content << "require_relative '#{relative_path}'"
            end
            content << ""
            content << 'say "Applying template..."'
            content << "```"
            content << ""
            
            # Ruby version phase
            content << "## 010_PHASE_RubyVersion"
            content << ""
            content << "*Ruby version configuration (handled by Rails application setup)*"
            content << ""
            
            # Generate documentation for each generator
            generators.each do |generator|
              content << "## #{generator[:phase]}"
              content << ""
              content << "*#{get_phase_description(generator[:phase])}*"
              content << ""
              content << "**Generator Call:**"
              content << "```ruby"
              content << "say \"#~ #{generator[:phase]}\""
              content << "GitTemplate::Generators::#{generator[:class_name]}.execute"
              content << "```"
              content << ""
              
              # Try to get more details about what the generator does
              begin
                require generator[:file_path]
                generator_class = Object.const_get("GitTemplate::Generators::#{generator[:class_name]}")
                
                if generator_class.respond_to?(:execute)
                  content << "**What this generator does:**"
                  content << "- Executes the #{generator[:class_name]} generator"
                  content << "- Defined in: `#{File.basename(generator[:file_path])}`"
                  
                  # Try to extract method details
                  if File.exist?(generator[:file_path])
                    lines = File.readlines(generator[:file_path])
                    execute_method_start = lines.find_index { |line| line.strip.start_with?('def self.execute') }
                    if execute_method_start
                      # Look for comments or say statements that describe what it does
                      method_lines = lines[execute_method_start, 20]
                      descriptions = method_lines.select { |line| 
                        line.strip.start_with?('#') || line.include?('say') 
                      }.first(3)
                      
                      descriptions.each do |desc|
                        if desc.strip.start_with?('#')
                          content << "- #{desc.strip.gsub(/^#\s*/, '')}"
                        elsif desc.include?('say')
                          # Extract say message
                          if match = desc.match(/say\s+["']([^"']+)["']/)
                            content << "- #{match[1]}"
                          end
                        end
                      end
                    end
                  end
                end
              rescue => e
                content << "- Error loading generator details: #{e.message}"
              end
              
              content << ""
            end
            
            # Footer
            content << "## Template Phase Structure"
            content << ""
            content << "This template follows the git-template specialized phase architecture:"
            content << ""
            content << "- **010_PHASE**: Ruby version and basic configuration"
            content << "- **030_PHASE**: Gem dependencies and bundler setup"  
            content << "- **040_PHASE**: UI, views, and styling configuration"
            content << "- **050_PHASE**: Testing framework setup"
            content << "- **100_PHASE**: Application features and functionality"
            content << "- **900_PHASE**: Completion messages and next steps"
            content << ""
            content << "Each phase has a specific responsibility, making the template organized, maintainable, and easy to iterate on during development."
            content << ""
            content << "## Generator Calls Summary"
            content << ""
            generators.each do |generator|
              content << "- `GitTemplate::Generators::#{generator[:class_name]}.execute` - #{generator[:phase]}"
            end
            
            content.join("\n")
          end
          
          define_method :get_phase_description do |phase|
            case phase
            when /GemBundle/
              "Gem bundle configuration and dependencies"
            when /View/
              "View and UI configuration"
            when /Test/
              "Testing framework setup"
            when /Feature_Home/
              "Home page feature implementation"
            when /Feature_Post/
              "Post model and feature implementation"
            when /Complete/
              "Template completion and next steps"
            else
              "Template phase implementation"
            end
          end
          
          define_method :show_regenerated_template_details do |template_file, generators, options|
            puts "\n" + "="*80
            puts "REGENERATED TEMPLATE CONTENT"
            puts "="*80
            puts "File: #{template_file}"
            puts "Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            puts "\n```ruby"
            
            # Show the actual file content
            if File.exist?(template_file)
              File.readlines(template_file).each_with_index do |line, index|
                printf "%3d: %s", index + 1, line
              end
            end
            
            puts "```\n"
            
            # Show what each generator execute call would produce
            puts "="*80
            puts "GENERATOR EXECUTE OUTPUTS"
            puts "="*80
            
            generators.each do |generator|
              puts "\n#{'-'*60}"
              puts "Generator: #{generator[:name]}"
              puts "Phase: #{generator[:phase]}"
              puts "Class: GitTemplate::Generators::#{generator[:class_name]}"
              puts "#{'-'*60}"
              
              begin
                # Try to load and inspect the generator
                require generator[:file_path]
                generator_class = Object.const_get("GitTemplate::Generators::#{generator[:class_name]}")
                
                if generator_class.respond_to?(:execute)
                  puts "Execute method: ✓ Available"
                  
                  # Try to get method information
                  method_obj = generator_class.method(:execute)
                  puts "Method arity: #{method_obj.arity} parameters"
                  
                  # Show method source location if available
                  if method_obj.source_location
                    file, line = method_obj.source_location
                    puts "Defined at: #{File.basename(file)}:#{line}"
                  end
                  
                  # Try to show what the method would do (without actually executing it)
                  puts "\nMethod implementation preview:"
                  if File.exist?(generator[:file_path])
                    lines = File.readlines(generator[:file_path])
                    execute_method_start = lines.find_index { |line| line.strip.start_with?('def self.execute') }
                    if execute_method_start
                      # Show a few lines of the execute method
                      method_lines = lines[execute_method_start, 10]
                      method_lines.each_with_index do |line, idx|
                        puts "  #{execute_method_start + idx + 1}: #{line.rstrip}"
                        break if line.strip == 'end' && idx > 0
                      end
                    end
                  end
                else
                  puts "Execute method: ✗ Not available"
                end
                
              rescue => e
                puts "Error loading generator: #{e.message}"
              end
            end
            
            puts "\n" + "="*80
            puts "END OF REGENERATED TEMPLATE DETAILS"
            puts "="*80 + "\n"
          end
          

        end
      end
    end
  end
end