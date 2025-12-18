require_relative 'base'

module GitTemplate
  module Generators
    class View < Base
      def self.execute
        execute_with_messages do |data, messages|
          # File replacements
          say_next_message(messages, "Updating views...")
          say_next_message(messages)
          
          if data.const_defined?(:TITLE_REPLACEMENT)
            replacement = data::TITLE_REPLACEMENT
            gsub_file 'app/views/layouts/application.html.erb', 
              replacement[:from], 
              replacement[:to]
          end
          
          # CSS additions
          say_next_message(messages, "Adding styles...")
          say_next_message(messages)
          
          if data.const_defined?(:CSS_CONTENT)
            append_to_file 'app/assets/stylesheets/application.css', data::CSS_CONTENT
          end
        end
      end
    end
  end
end