# Configure Rails application settings
say "Configuring Rails application...", :green

# Configure generators
environment do
  <<-RUBY
    # Configure generators
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: true,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: false,
        request_specs: true
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  RUBY
end

# Configure time zone and locale
environment do
  <<-RUBY
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "UTC"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :en
  RUBY
end

# Configure Active Storage
environment do
  <<-RUBY
    # Configure Active Storage
    config.active_storage.variant_processor = :vips
  RUBY
end

say "✓ Rails configuration complete", :green
