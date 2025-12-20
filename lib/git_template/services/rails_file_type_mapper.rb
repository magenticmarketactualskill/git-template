module GitTemplate
  module Services
    class RailsFileTypeMapper
      # Mapping patterns to generator classes
      MAPPINGS = [
        { pattern: /^Gemfile$/, generator: 'GitTemplate::Generators::Gemfile' },
        { pattern: /^config\/routes\.rb$/, generator: 'GitTemplate::Generators::Routes' },
        { pattern: /^app\/models\/.*\.rb$/, generator: 'GitTemplate::Generators::Model' },
        { pattern: /^app\/controllers\/.*\.rb$/, generator: 'GitTemplate::Generators::Controller' },
        { pattern: /^db\/migrate\/.*\.rb$/, generator: 'GitTemplate::Generators::Migration' },
        { pattern: /^app\/mailers\/.*\.rb$/, generator: 'GitTemplate::Generators::Mailer' },
        { pattern: /^app\/jobs\/.*\.rb$/, generator: 'GitTemplate::Generators::Job' },
        { pattern: /^app\/helpers\/.*\.rb$/, generator: 'GitTemplate::Generators::Helper' },
        { pattern: /^config\/.*\.rb$/, generator: 'GitTemplate::Generators::Config' },
      ].freeze
      
      # Map a file path to its generator class
      # @param relative_path [String] Path relative to repository root
      # @return [String, nil] Generator class name or nil if no mapping found
      def self.map_file(relative_path)
        MAPPINGS.each do |mapping|
          return mapping[:generator] if relative_path.match?(mapping[:pattern])
        end
        nil
      end
      
      # Get all Ruby files in a directory tree
      # @param root_path [String] Root directory to scan
      # @return [Array<Hash>] Array of file info hashes with :path and :generator
      def self.scan_repository(root_path)
        results = []
        
        Dir.glob("**/*", base: root_path).each do |relative_path|
          full_path = File.join(root_path, relative_path)
          next if File.directory?(full_path)
          
          generator = map_file(relative_path)
          results << {
            path: relative_path,
            generator: generator,
            full_path: full_path
          }
        end
        
        results
      end
      
      # Build a tree structure with generator mappings
      # @param root_path [String] Root directory to scan
      # @return [Hash] Tree structure with files and their generators
      def self.build_tree(root_path)
        files = scan_repository(root_path)
        tree = {}
        
        files.each do |file_info|
          parts = file_info[:path].split('/')
          current = tree
          
          parts.each_with_index do |part, index|
            current[part] ||= {}
            
            if index == parts.length - 1
              # Leaf node - add generator info
              current[part][:_generator] = file_info[:generator]
              current[part][:_path] = file_info[:path]
            else
              # Directory node
              current = current[part]
            end
          end
        end
        
        tree
      end
      
      # Format tree for display
      # @param tree [Hash] Tree structure from build_tree
      # @param indent [Integer] Current indentation level
      # @return [String] Formatted tree output
      def self.format_tree(tree, indent = 0)
        lines = []
        prefix = "  " * indent
        
        tree.each do |name, subtree|
          next if name.start_with?('_')
          
          if subtree[:_generator]
            # File with generator mapping
            generator_name = subtree[:_generator] || 'Unknown'
            lines << "#{prefix}#{name} → #{generator_name}"
          elsif subtree.keys.any? { |k| !k.start_with?('_') }
            # Directory with children
            lines << "#{prefix}#{name}/"
            lines << format_tree(subtree, indent + 1)
          end
        end
        
        lines.join("\n")
      end
    end
  end
end
