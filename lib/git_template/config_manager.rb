# ConfigManager
#
# Manages reading and parsing the ~/.git-template configuration file

require 'fileutils'

module GitTemplate
  class ConfigManager
    CONFIG_FILE = File.expand_path('~/.git-template')
    
    def self.load_config
      return {} unless File.exist?(CONFIG_FILE)
      
      config = {}
      current_section = nil
      
      File.readlines(CONFIG_FILE).each do |line|
        line = line.strip
        
        # Skip comments and empty lines
        next if line.empty? || line.start_with?('#')
        
        # Parse section headers
        if line.match(/^\[(.+)\]$/)
          current_section = $1
          config[current_section] = {}
          next
        end
        
        # Parse key-value pairs
        if line.include?('=') && current_section
          key, value = line.split('=', 2).map(&:strip)
          config[current_section][key] = value
        end
      end
      
      config
    end
    
    def self.get_default_path
      config = load_config
      config.dig('default', 'path')
    end
    
    def self.get_default_url
      config = load_config
      config.dig('default', 'url')
    end
    
    def self.get_path_for(name)
      config = load_config
      config.dig('paths', name) || config.dig('default', 'path')
    end
    
    def self.get_url_for(name)
      config = load_config
      config.dig('urls', name) || config.dig('default', 'url')
    end
    
    def self.config_exists?
      File.exist?(CONFIG_FILE)
    end
    
    def self.create_default_config
      config_content = <<~CONFIG
        # Git Template Configuration
        # This file stores default configurations for git-template operations

        [default]
        path = examples/rails8-simple
        url = https://github.com/magenticmarketactualskill/rails8-simple.git

        [paths]
        # Common paths for different project types
        rails8-simple = examples/rails8-simple

        [urls]
        # Repository URLs
        rails8-simple = https://github.com/magenticmarketactualskill/rails8-simple.git
      CONFIG
      
      File.write(CONFIG_FILE, config_content)
    end
  end
end