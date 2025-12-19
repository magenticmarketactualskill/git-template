module GitTemplate
  module Generators
    class Base
      def self.generate(config)
        new(config).generate
      end
      
      def initialize(config)
        @config = config
      end
      
      def generate
        raise NotImplementedError, "Subclasses must implement #generate"
      end
    end
  end
end