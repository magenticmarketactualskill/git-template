module GitTemplate
  module Generators
    module Routes
      def self.included(base)
        base.class_eval do
          @routes = []
        end
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        attr_reader :routes
        
        def golden_text
          build_routes_content
        end
        
        # Parse a routes.rb file and extract route definitions
        def parse(file_path)
          content = File.read(file_path)
          routes = []
          
          # Extract route definitions (simplified parser)
          content.each_line do |line|
            stripped = line.strip
            
            # Skip comments and blank lines
            next if stripped.empty? || stripped.start_with?('#')
            
            # Skip the draw block declaration
            next if stripped.include?('routes.draw')
            
            # Skip end statements
            next if stripped == 'end'
            
            # Capture route definitions
            if stripped.match?(/^\s*(get|post|put|patch|delete|resource|resources|root|namespace|scope|match)\s+/)
              routes << stripped
            end
          end
          
          routes
        end
        
        private
        
        def build_routes_content
          lines = ["Rails.application.routes.draw do"]
          
          @routes&.each do |route|
            lines << "  #{route}"
          end
          
          lines << "end"
          lines.join("\n")
        end
      end
    end
  end
end
