require_relative '../services/rails_file_type_mapper'
require_relative '../services/reverse_engineer_parser'
require_relative '../services/template_processor'

module GitTemplate
  module Command
    module ReverseEngineer
      def self.included(base)
        base.class_eval do
          desc "reverse_engineer", "Analyze Rails repository and map files to generators"
          option :path, type: :string, required: true, desc: "Path to Rails repository"
          option :list, type: :boolean, default: false, desc: "Display tree with generator mappings"
          option :generator, type: :string, desc: "Filter by specific generator type (e.g., model, controller, migration)"
          option :execute, type: :boolean, default: false, desc: "Generate and execute template to recreate files"
          option :output, type: :string, desc: "Output directory for templated files (defaults to templated/<repo_name>)"
          
          def reverse_engineer
            repo_path = options[:path]
            
            unless File.directory?(repo_path)
              @logger.error "Path does not exist: #{repo_path}"
              return
            end
            
            @logger.info "Analyzing Rails repository at: #{repo_path}"
            
            if options[:execute]
              execute_reverse_engineering(repo_path)
            elsif options[:list]
              display_tree(repo_path)
            else
              analyze_repository(repo_path)
            end
          end
          
          private
          
          def display_tree(repo_path)
            tree = GitTemplate::Services::RailsFileTypeMapper.build_tree(repo_path)
            
            # Filter tree by generator if specified
            if options[:generator]
              tree = filter_tree_by_generator(tree, normalize_generator_name(options[:generator]))
            end
            
            formatted = GitTemplate::Services::RailsFileTypeMapper.format_tree(tree)
            
            title = "Repository File Tree with Generator Mappings"
            title += " (filtered: #{options[:generator]})" if options[:generator]
            
            puts "\n" + "=" * 80
            puts title
            puts "=" * 80
            puts formatted
            puts "=" * 80 + "\n"
          end
          
          def analyze_repository(repo_path)
            files = GitTemplate::Services::RailsFileTypeMapper.scan_repository(repo_path)
            
            # Filter by generator if specified
            if options[:generator]
              target_generator = normalize_generator_name(options[:generator])
              files = files.select { |f| f[:generator] == target_generator }
            end
            
            # Group by generator type
            by_generator = files.group_by { |f| f[:generator] || 'Unmapped' }
            
            title = "Repository Analysis"
            title += " (filtered: #{options[:generator]})" if options[:generator]
            
            puts "\n" + "=" * 80
            puts title
            puts "=" * 80
            puts "Total files: #{files.count}"
            puts "\nFiles by generator type:"
            
            by_generator.sort_by { |gen, _| gen }.each do |generator, file_list|
              puts "\n#{generator} (#{file_list.count} files):"
              file_list.first(5).each do |file|
                puts "  - #{file[:path]}"
              end
              puts "  ... and #{file_list.count - 5} more" if file_list.count > 5
            end
            
            puts "=" * 80 + "\n"
          end
          
          # Normalize generator name from short form to full class name
          def normalize_generator_name(generator_name)
            # If already a full class name, return as-is
            return generator_name if generator_name.include?('::')
            
            # Convert short name to full class name
            short_name = generator_name.downcase
            class_name = short_name.split('_').map(&:capitalize).join
            "GitTemplate::Generators::#{class_name}"
          end
          
          # Filter tree structure to only include files matching the target generator
          def filter_tree_by_generator(tree, target_generator)
            filtered = {}
            
            tree.each do |name, subtree|
              next if name.start_with?('_')
              
              if subtree[:_generator]
                # File node - include if generator matches
                if subtree[:_generator] == target_generator
                  filtered[name] = subtree
                end
              elsif subtree.keys.any? { |k| !k.start_with?('_') }
                # Directory node - recursively filter
                filtered_subtree = filter_tree_by_generator(subtree, target_generator)
                filtered[name] = filtered_subtree unless filtered_subtree.empty?
              end
            end
            
            filtered
          end
          
          # Execute reverse engineering: parse files and generate template_part files
          def execute_reverse_engineering(repo_path)
            files = GitTemplate::Services::RailsFileTypeMapper.scan_repository(repo_path)
            
            # Filter by generator if specified
            if options[:generator]
              target_generator = normalize_generator_name(options[:generator])
              files = files.select { |f| f[:generator] == target_generator }
            end
            
            if files.empty?
              puts "No files found matching the specified criteria."
              return
            end
            
            puts "\n" + "=" * 80
            puts "REVERSE ENGINEERING EXECUTION"
            puts "=" * 80
            puts "Found #{files.count} file(s) to reverse engineer"
            puts "=" * 80 + "\n"
            
            # Determine output directory
            repo_name = File.basename(File.expand_path(repo_path))
            output_dir = options[:output] || File.join(Dir.pwd, 'templated', repo_name)
            
            # Create .git_template/template_part directory
            template_part_dir = File.join(output_dir, '.git_template', 'template_part')
            FileUtils.mkdir_p(template_part_dir)
            
            # Generate template_part files for each generator type
            generated_files = []
            by_generator = files.group_by { |f| f[:generator] }
            
            by_generator.each_with_index do |(generator, file_list), index|
              generator_name = extract_generator_name(generator)
              template_part_content = generate_template_part(generator, generator_name, file_list, repo_path, index + 1)
              
              template_part_file = File.join(template_part_dir, "#{generator_name.downcase}_generator_#{format('%04d', index + 1)}.rb")
              File.write(template_part_file, template_part_content)
              generated_files << template_part_file
              
              puts "Generated template_part: #{File.basename(template_part_file)}"
              puts "  Generator: #{generator}"
              puts "  Files: #{file_list.count}"
            end
            
            puts "\n" + "=" * 80
            puts "REVERSE ENGINEERING COMPLETE"
            puts "=" * 80
            puts "Output directory: #{output_dir}"
            puts "Template parts directory: #{template_part_dir}"
            puts "Generated #{generated_files.count} template_part file(s):"
            generated_files.each { |f| puts "  - #{File.basename(f)}" }
            puts "=" * 80 + "\n"
          end
          
          # Generate template content from parsed files
          def generate_template_from_files(files, repo_path)
            content = []
            
            # Header
            content << "# Rails Template - Reverse Engineered"
            content << "# Generated by git-template reverse_engineer command"
            content << "# Source: #{repo_path}"
            content << "# Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            content << ""
            
            # Group files by generator type
            by_generator = files.group_by { |f| f[:generator] }
            
            by_generator.each do |generator, file_list|
              content << "# #{generator} (#{file_list.count} file(s))"
              content << ""
              
              file_list.each do |file_info|
                full_path = File.join(repo_path, file_info[:path])
                
                case generator
                when 'GitTemplate::Generators::Routes'
                  routes = GitTemplate::Services::ReverseEngineerParser.parse_routes(full_path)
                  content << "# Create #{file_info[:path]}"
                  content << "create_file 'config/routes.rb' do <<-RUBY"
                  content << "Rails.application.routes.draw do"
                  routes.each { |route| content << "  #{route}" }
                  content << "end"
                  content << "RUBY"
                  content << "end"
                  content << ""
                  
                when 'GitTemplate::Generators::Model'
                  model_info = GitTemplate::Services::ReverseEngineerParser.parse_model(full_path)
                  content << "# Create #{file_info[:path]}"
                  content << "create_file '#{file_info[:path]}' do <<-RUBY"
                  content << model_info[:content]
                  content << "RUBY"
                  content << "end"
                  content << ""
                  
                when 'GitTemplate::Generators::Controller'
                  controller_info = GitTemplate::Services::ReverseEngineerParser.parse_controller(full_path)
                  content << "# Create #{file_info[:path]}"
                  content << "create_file '#{file_info[:path]}' do <<-RUBY"
                  content << controller_info[:content]
                  content << "RUBY"
                  content << "end"
                  content << ""
                  
                else
                  # Generic file creation
                  file_content = File.read(full_path)
                  content << "# Create #{file_info[:path]}"
                  content << "create_file '#{file_info[:path]}' do <<-RUBY"
                  content << file_content
                  content << "RUBY"
                  content << "end"
                  content << ""
                end
              end
            end
            
            content.join("\n")
          end
          
          # Extract generator name from full class path
          def extract_generator_name(generator_class)
            # E.g., "GitTemplate::Generators::Routes" => "Routes"
            generator_class.split('::').last
          end
          
          # Generate a template_part file for a specific generator
          def generate_template_part(generator_class, generator_name, file_list, repo_path, sequence)
            content = []
            
            # Header with load path setup
            content << "lib_path = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib')"
            content << 'puts "Adding to load path: #{lib_path}"'
            content << 'puts "Resolved path: #{File.expand_path(lib_path)}"'
            content << "$LOAD_PATH.unshift(lib_path)"
            content << ""
            content << ""
            
            # Class definition
            class_name = "#{generator_name}Generator#{format('%04d', sequence)}"
            content << "class #{class_name} < GitTemplate::Generators::Base"
            content << "  include GitTemplate::Generators::#{generator_name}"
            content << "  "
            content << "  "
            
            # Generate content based on generator type
            case generator_class
            when 'GitTemplate::Generators::Routes'
              generate_routes_template_part(content, file_list, repo_path)
            when 'GitTemplate::Generators::Model'
              generate_model_template_part(content, file_list, repo_path)
            when 'GitTemplate::Generators::Controller'
              generate_controller_template_part(content, file_list, repo_path)
            when 'GitTemplate::Generators::Helper'
              generate_helper_template_part(content, file_list, repo_path)
            else
              generate_generic_template_part(content, file_list, repo_path)
            end
            
            content << "end"
            content.join("\n")
          end
          
          # Generate routes template_part content
          def generate_routes_template_part(content, file_list, repo_path)
            file_list.each do |file_info|
              full_path = File.join(repo_path, file_info[:path])
              routes = GitTemplate::Services::ReverseEngineerParser.parse_routes(full_path)
              
              content << "  repo_path '#{file_info[:path]}'"
              content << "  "
              
              # Add routes using @routes class variable approach
              content << "  @routes = ["
              routes.each do |route|
                content << "    #{route.inspect},"
              end
              content << "  ]"
            end
          end
          
          # Generate model template_part content
          def generate_model_template_part(content, file_list, repo_path)
            file_list.each do |file_info|
              full_path = File.join(repo_path, file_info[:path])
              model_content = File.read(full_path)
              
              content << "  repo_path '#{file_info[:path]}'"
              content << "  "
              content << "  golden_text <<~RUBY"
              model_content.each_line do |line|
                content << "    #{line.rstrip}"
              end
              content << "  RUBY"
            end
          end
          
          # Generate controller template_part content
          def generate_controller_template_part(content, file_list, repo_path)
            file_list.each do |file_info|
              full_path = File.join(repo_path, file_info[:path])
              controller_content = File.read(full_path)
              
              content << "  repo_path '#{file_info[:path]}'"
              content << "  "
              content << "  golden_text <<~RUBY"
              controller_content.each_line do |line|
                content << "    #{line.rstrip}"
              end
              content << "  RUBY"
            end
          end
          
          # Generate helper template_part content
          def generate_helper_template_part(content, file_list, repo_path)
            file_list.each do |file_info|
              full_path = File.join(repo_path, file_info[:path])
              helper_content = File.read(full_path)
              
              content << "  repo_path '#{file_info[:path]}'"
              content << "  "
              content << "  golden_text <<~RUBY"
              helper_content.each_line do |line|
                content << "    #{line.rstrip}"
              end
              content << "  RUBY"
            end
          end
          
          # Generate generic template_part content
          def generate_generic_template_part(content, file_list, repo_path)
            file_list.each do |file_info|
              full_path = File.join(repo_path, file_info[:path])
              file_content = File.read(full_path)
              
              content << "  repo_path '#{file_info[:path]}'"
              content << "  "
              content << "  golden_text <<~RUBY"
              file_content.each_line do |line|
                content << "    #{line.rstrip}"
              end
              content << "  RUBY"
            end
          end
        end
      end
    end
  end
end
