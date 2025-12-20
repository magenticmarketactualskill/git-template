module GitTemplate
  module Services
    class ReverseEngineerParser
      # Parse a model file and extract basic information
      def self.parse_model(file_path)
        content = File.read(file_path)
        class_name = File.basename(file_path, '.rb').split('_').map(&:capitalize).join
        
        {
          class_name: class_name,
          content: content
        }
      end
      
      # Parse a controller file and extract actions
      def self.parse_controller(file_path)
        content = File.read(file_path)
        class_name = File.basename(file_path, '.rb').split('_').map(&:capitalize).join
        
        # Extract action methods (simplified)
        actions = []
        content.each_line do |line|
          if line.strip.match?(/^def\s+(\w+)/)
            actions << $1
          end
        end
        
        {
          class_name: class_name,
          actions: actions,
          content: content
        }
      end
      
      # Parse a migration file
      def self.parse_migration(file_path)
        content = File.read(file_path)
        
        {
          filename: File.basename(file_path),
          content: content
        }
      end
      
      # Generic file parser - just returns content
      def self.parse_generic(file_path)
        {
          filename: File.basename(file_path),
          relative_path: file_path,
          content: File.read(file_path)
        }
      end
    end
  end
end
