# ConfigCommand Concern
#
# This command manages the ~/.git-template configuration file

require_relative 'base'
require_relative '../config_manager'

module GitTemplate
  module Command
    module Config
      def self.included(base)
        base.class_eval do
          desc "config", "Show current configuration from ~/.git-template"
          add_common_options
          option :create, type: :boolean, default: false, desc: "Create default config file if it doesn't exist"
          
          define_method :config do
            execute_with_error_handling("config", options) do
              log_command_execution("config", [], options)
              setup_environment(options)
              
              # Create config if requested and doesn't exist
              if options[:create] && !ConfigManager.config_exists?
                ConfigManager.create_default_config
                puts "✅ Created default configuration at ~/.git-template"
              end
              
              # Check if config exists
              unless ConfigManager.config_exists?
                puts "❌ Configuration file ~/.git-template does not exist"
                puts "   Run 'git-template config --create' to create a default configuration"
                return create_error_response("config", "Configuration file not found")
              end
              
              # Load and display config
              config = ConfigManager.load_config
              
              puts "📋 Git Template Configuration (~/.git-template)"
              puts "=" * 50
              
              if config.empty?
                puts "Configuration file is empty or invalid"
              else
                config.each do |section, values|
                  puts "\n[#{section}]"
                  values.each do |key, value|
                    puts "  #{key} = #{value}"
                  end
                end
              end
              
              puts "\n🔧 Current Defaults:"
              puts "  Default Path: #{ConfigManager.get_default_path || 'Not set'}"
              puts "  Default URL:  #{ConfigManager.get_default_url || 'Not set'}"
              
              create_success_response("config", {
                config_file: ConfigManager::CONFIG_FILE,
                config_exists: true,
                default_path: ConfigManager.get_default_path,
                default_url: ConfigManager.get_default_url
              })
            end
          end
        end
      end
    end
  end
end