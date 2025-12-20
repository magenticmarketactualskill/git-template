require_relative 'metadata'

module GitTemplate
  module Generators
    class Base
      include Metadata
      
      # explicitly set
      attr_reader :golden_text
      
      #inferred from context
      attr_reader :repo, :repo_path, :metadata
      
      def self.golden_text(text = nil)
        if text
          @golden_text = text
        else
          @golden_text
        end
      end
      
      def self.repo_path(path = nil)
        if path
          @repo_path = path
        else
          @repo_path
        end
      end
      
      def self.generate(config)
        new(config).generate
      end
      
      def initialize(config)
        @config = config
        @golden_text = self.class.golden_text
        @repo_path = self.class.repo_path
        @metadata = build_metadata
      end
      
      def generate
        raise NotImplementedError, "Subclasses must implement #generate"
      end
    end
  end
end