# frozen_string_literal: true

module Submoduler
  class RepositoryContext
    attr_reader :path, :mode, :submodules, :parent_path
    
    def initialize(path = '.')
      @path = File.expand_path(path)
      @mode = detect_mode
      @submodules = load_submodules
      @parent_path = detect_parent_path
    end
    
    def parent?
      @mode == :parent
    end
    
    def child?
      @mode == :child
    end
    
    def has_submodules?
      !@submodules.empty?
    end
    
    def git_repository?
      File.exist?(File.join(@path, '.git'))
    end
    
    private
    
    def detect_mode
      ModeDetector.new(@path).detect
    end
    
    def load_submodules
      gitmodules_path = File.join(@path, '.gitmodules')
      return [] unless File.exist?(gitmodules_path)
      
      parse_gitmodules(gitmodules_path)
    end
    
    def parse_gitmodules(path)
      submodules = []
      current_submodule = nil
      
      File.readlines(path).each do |line|
        line = line.strip
        
        if line.match(/^\[submodule "(.+)"\]$/)
          current_submodule = { name: $1 }
          submodules << current_submodule
        elsif line.match(/^\s*path\s*=\s*(.+)$/) && current_submodule
          current_submodule[:path] = $1.strip
        elsif line.match(/^\s*url\s*=\s*(.+)$/) && current_submodule
          current_submodule[:url] = $1.strip
        end
      end
      
      submodules
    rescue => e
      raise GitOperationError.new('parse_gitmodules', e.message)
    end
    
    def detect_parent_path
      return nil unless child?
      
      git_file = File.join(@path, '.git')
      return nil unless File.exist?(git_file)
      
      content = File.read(git_file)
      return nil unless content.start_with?('gitdir:')
      
      extract_parent_from_gitdir(content)
    end
    
    def extract_parent_from_gitdir(content)
      # Extract the gitdir path and work backwards to find parent
      gitdir = content.sub('gitdir:', '').strip
      
      # Gitdir typically points to .git/modules/submodule_name
      # We need to find the parent repository root
      parts = gitdir.split('/')
      modules_index = parts.rindex('modules')
      
      return nil unless modules_index && modules_index > 0
      
      # Parent is typically 2 levels up from the modules directory
      parent_parts = parts[0..modules_index-1]
      parent_parts.pop if parent_parts.last == '.git'
      
      File.join(*parent_parts)
    rescue => e
      raise GitOperationError.new('detect_parent_path', e.message)
    end
  end
end