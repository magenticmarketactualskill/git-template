# frozen_string_literal: true

module Submoduler
  class ModeDetector
    def initialize(path = '.')
      @path = File.expand_path(path)
    end
    
    def self.detect(path = '.')
      new(path).detect
    end
    
    def detect
      # Check for explicit configuration first
      config = load_config
      return config.mode unless config.auto_mode?
      
      # Automatic detection based on git context
      return :parent if has_gitmodules?
      return :child if is_submodule?
      
      # Check for submoduler config without explicit mode
      return :auto if has_submoduler_config?
      
      # If we can't determine the mode, raise an error with helpful guidance
      raise AmbiguousContextError
    end
    
    def can_detect_automatically?
      has_gitmodules? || is_submodule?
    end
    
    def detection_hints
      hints = []
      
      if has_gitmodules?
        hints << "Found .gitmodules file - suggests parent mode"
      end
      
      if is_submodule?
        hints << "Repository appears to be a git submodule - suggests child mode"
      end
      
      if has_submoduler_config?
        hints << "Found .submoduler.ini configuration file"
      end
      
      if !git_repository?
        hints << "Not a git repository - initialize git first"
      end
      
      hints
    end
    
    private
    
    def load_config
      Configuration.load_from_file(File.join(@path, '.submoduler.ini'))
    rescue ConfigurationError
      Configuration.new
    end
    
    def has_gitmodules?
      File.exist?(File.join(@path, '.gitmodules'))
    end
    
    def is_submodule?
      git_file = File.join(@path, '.git')
      return false unless File.exist?(git_file)
      
      # If .git is a file (not directory), it's likely a submodule
      return false if File.directory?(git_file)
      
      content = File.read(git_file)
      content.start_with?('gitdir:')
    rescue
      false
    end
    
    def has_submoduler_config?
      File.exist?(File.join(@path, '.submoduler.ini'))
    end
    
    def git_repository?
      File.exist?(File.join(@path, '.git'))
    end
  end
end