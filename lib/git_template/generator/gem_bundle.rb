require_relative 'base'

module GitTemplate
  module Generators
    class GemBundle < Base
      def generate
        output = []
        output << 'source "https://rubygems.org"'
        output << ""
        
        @config.groups.each do |group|
          if group.gem_text
            if group.envs.any?
              output << "group #{group.envs.map { |env| ":#{env}" }.join(', ')} do"
              output << group.gem_text.strip
              output << "end"
            else
              output << group.gem_text.strip
            end
          end
          output << ""
        end
        
        gemfile_content = output.join("\n")
        File.write('Gemfile', gemfile_content)
        puts "Generated Gemfile"
      end
    end
    
    class Config
      attr_accessor :id, :groups
      
      def initialize(id:, groups:)
        @id = id
        @groups = groups
      end
    end
    
    class GemGroup
      attr_accessor :envs, :gem_text, :gems
      
      def initialize(envs:, gem_text: nil, gems: [])
        @envs = envs
        @gem_text = gem_text
        @gems = gems
      end
    end
  end
end