# CreateTemplatedFolderPublic Module
#
# This module ensures the create_templated_folder method is public
# by being included after all other modules

module GitTemplate
  module Command
    module CreateTemplatedFolderPublic
      def self.included(base)
        base.class_eval do
          # Make sure create_templated_folder is public
          public :create_templated_folder if private_method_defined?(:create_templated_folder)
        end
      end
    end
  end
end