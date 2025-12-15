# frozen_string_literal: true

module Submoduler
  class Configuration
    attr_accessor :mode, :require_tests_pass, :separate_repo
    
    def initialize
      @mode = :auto
      @require_tests_pass = true
      @separate_repo = true
    end
    
    def self.load_from_file(path = '.submoduler.ini')
      return new unless File.exist?(path)
      
      config = new
      content = File.read(path)
      
      config.mode = extract_mode(content)
      config.require_tests_pass = extract_boolean(content, 'require_tests_pass')
      config.separate_repo = extract_boolean(content, 'separate_repo')
      
      config
    rescue => e
      raise ConfigurationError, "Failed to load configuration from #{path}: #{e.message}"
    end
    
    def save_to_file(path = '.submoduler.ini')
      content = generate_ini_content
      File.write(path, content)
    rescue => e
      raise ConfigurationError, "Failed to save configuration to #{path}: #{e.message}"
    end
    
    def parent_mode?
      @mode == :parent
    end
    
    def child_mode?
      @mode == :child
    end
    
    def auto_mode?
      @mode == :auto
    end
    
    private
    
    def self.extract_mode(content)
      parent = content.match(/submodule_parent=(true|false)/)&.captures&.first == 'true'
      child = content.match(/submodule_child=(true|false)/)&.captures&.first == 'true'
      
      return :parent if parent && !child
      return :child if child && !parent
      :auto
    end
    
    def self.extract_boolean(content, key)
      match = content.match(/#{key}=(true|false)/)
      match&.captures&.first == 'true'
    end
    
    def generate_ini_content
      <<~INI
        [default]
        \tsubmodule_parent=#{mode == :parent}
        \tsubmodule_child=#{mode == :child}
        \trequire_tests_pass=#{require_tests_pass}
        \tseparate_repo=#{separate_repo}
      INI
    end
  end
end