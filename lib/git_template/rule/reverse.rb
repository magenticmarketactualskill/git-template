module GitTemplate
  module Rule
    module Reverse
      def self.included(base)
        base.class_eval do
          def reverse_path_ok?(path)
            expanded_path = File.expand_path(path)
            
            unless File.exist?(expanded_path)
              @logger.error "Path does not exist: #{expanded_path}"
              raise ArgumentError, "Path does not exist: #{expanded_path}"
            end
            
            unless File.directory?(expanded_path)
              @logger.error "Path is not a directory: #{expanded_path}"
              raise ArgumentError, "Path is not a directory: #{expanded_path}"
            end
            
            expanded_path
          end
        end   
      end
    end
  end
end
