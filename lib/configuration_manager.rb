# ConfigurationManager - Handles user preference collection, validation, and storage
#
# This class manages the collection of user preferences that determine which modules
# to apply during template execution. It provides validation, storage, and access
# to configuration throughout the template process.

class ConfigurationManager
  attr_reader :template_context, :configuration

  # Default configuration schema with validation rules
  DEFAULT_CONFIGURATION = {
    use_redis: { type: :boolean, default: false, prompt: "Use Redis? (no = use redis-emulator)" },
    use_active_data_flow: { type: :boolean, default: false, prompt: "Include ActiveDataFlow integration?" },
    use_docker: { type: :boolean, default: false, prompt: "Setup Docker/Kamal deployment?" },
    generate_sample_models: { type: :boolean, default: false, prompt: "Generate sample Product models?" },
    setup_admin: { type: :boolean, default: false, prompt: "Setup admin interface?" }
  }.freeze

  def initialize(template_context)
    @template_context = template_context
    @configuration = {}
    @configuration_schema = DEFAULT_CONFIGURATION.dup
  end

  def collect_preferences
    @template_context.say "Collecting configuration preferences...\n", :green
    
    @configuration_schema.each do |key, config_def|
      collect_preference(key, config_def)
    end
    
    validate_configuration
    @template_context.say "✓ Configuration collection complete\n", :green
  end

  def validate_configuration
    @configuration_schema.each do |key, config_def|
      value = @configuration[key]
      
      unless valid_value?(value, config_def[:type])
        raise ConfigurationError, "Invalid value for #{key}: #{value}. Expected #{config_def[:type]}"
      end
    end
  end

  def get(key, default = nil)
    @configuration.fetch(key.to_sym, default)
  end

  def set(key, value)
    key_sym = key.to_sym
    
    if @configuration_schema.key?(key_sym)
      config_def = @configuration_schema[key_sym]
      unless valid_value?(value, config_def[:type])
        raise ConfigurationError, "Invalid value for #{key}: #{value}. Expected #{config_def[:type]}"
      end
    end
    
    @configuration[key_sym] = value
  end

  def to_hash
    @configuration.dup
  end

  # Extensibility: Add new configuration options
  def add_configuration_option(key, type:, default: nil, prompt:)
    @configuration_schema[key.to_sym] = {
      type: type,
      default: default,
      prompt: prompt
    }
  end

  # Check if a configuration key exists
  def has_key?(key)
    @configuration.key?(key.to_sym)
  end

  # Get all configuration keys
  def keys
    @configuration.keys
  end

  private

  def collect_preference(key, config_def)
    max_attempts = 3
    attempts = 0
    
    loop do
      attempts += 1
      
      begin
        value = prompt_user(config_def[:prompt], config_def[:default])
        parsed_value = parse_value(value, config_def[:type])
        
        if valid_value?(parsed_value, config_def[:type])
          @configuration[key] = parsed_value
          break
        else
          raise ConfigurationError, "Invalid input. Expected #{config_def[:type]}"
        end
        
      rescue ConfigurationError => e
        if attempts >= max_attempts
          @template_context.say "Maximum attempts reached. Using default value: #{config_def[:default]}", :yellow
          @configuration[key] = config_def[:default]
          break
        else
          @template_context.say "#{e.message}. Please try again (#{attempts}/#{max_attempts})", :red
        end
      end
    end
  end

  def prompt_user(prompt, default)
    if @template_context.respond_to?(:yes?)
      # For boolean prompts, use Rails template yes? method
      @template_context.yes?(prompt)
    else
      # Fallback for other types or testing
      @template_context.ask(prompt) || default
    end
  end

  def parse_value(value, type)
    case type
    when :boolean
      # yes? method already returns boolean
      value
    when :string
      value.to_s
    when :integer
      value.to_i
    when :float
      value.to_f
    else
      value
    end
  end

  def valid_value?(value, type)
    case type
    when :boolean
      [true, false].include?(value)
    when :string
      value.is_a?(String)
    when :integer
      value.is_a?(Integer)
    when :float
      value.is_a?(Float) || value.is_a?(Integer)
    else
      true # Unknown types are considered valid
    end
  end

  class ConfigurationError < StandardError; end
end