module GitTemplate
  module TemplateGenerators
    class CompletionGenerator
      def self.execute
        text_data.each do |line_data|
          if line_data.length == 1
            say line_data[0]
          else
            say line_data[0], line_data[1]
          end
        end
      end
      
      def self.text_data
        raise "Must override text_data method"
      end
    end
  end
end