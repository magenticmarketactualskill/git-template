# frozen_string_literal: true

require_relative 'submoduler/version'
require_relative 'submoduler/mode_detector'
require_relative 'submoduler/configuration'
require_relative 'submoduler/repository_context'
require_relative 'submoduler/component_manager'
require_relative 'submoduler/repository_operations'
require_relative 'submoduler/cli'
require_relative 'submoduler/errors'

module Submoduler
  class << self
    def mode
      @mode ||= ModeDetector.detect
    end
    
    def parent?
      mode == :parent
    end
    
    def child?
      mode == :child
    end
    
    def configure
      yield(configuration)
    end
    
    def configuration
      @configuration ||= Configuration.new
    end
    
    def reset!
      @mode = nil
      @configuration = nil
    end
  end
end