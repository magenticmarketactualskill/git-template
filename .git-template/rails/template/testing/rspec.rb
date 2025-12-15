# Setup RSpec for testing
say "Setting up RSpec...", :green

# Add RSpec gems
gem_group :development, :test do
  gem "rspec-rails", "~> 6.0", comment: "RSpec testing framework for Rails"
  gem "factory_bot_rails", comment: "Fixtures replacement with a straightforward definition syntax"
  gem "faker", comment: "Generate fake data for testing"
end

gem_group :test do
  gem "shoulda-matchers", comment: "Simple one-liner tests for common Rails functionality"
  gem "database_cleaner-active_record", comment: "Strategies for cleaning databases in tests"
  gem "webmock", comment: "Library for stubbing HTTP requests"
  gem "vcr", comment: "Record HTTP interactions for testing"
end

# RSpec will be installed via rails generate rspec:install in after_bundle
after_bundle do
  # Generate RSpec configuration
  generate "rspec:install"
  
  # Configure RSpec
  gsub_file "spec/rails_helper.rb", "# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }", 
            "Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }"
  
  # Create spec/support directory
  run "mkdir -p spec/support"
  
  # Create FactoryBot configuration
  file "spec/support/factory_bot.rb", <<~RUBY
    # FactoryBot configuration
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
  RUBY
  
  # Create DatabaseCleaner configuration
  file "spec/support/database_cleaner.rb", <<~RUBY
    # DatabaseCleaner configuration
    RSpec.configure do |config|
      config.before(:suite) do
        DatabaseCleaner.strategy = :transaction
        DatabaseCleaner.clean_with(:truncation)
      end

      config.around(:each) do |example|
        DatabaseCleaner.cleaning do
          example.run
        end
      end
    end
  RUBY
  
  # Create Shoulda Matchers configuration
  file "spec/support/shoulda_matchers.rb", <<~RUBY
    # Shoulda Matchers configuration
    Shoulda::Matchers.configure do |config|
      config.integrate do |with|
        with.test_framework :rspec
        with.library :rails
      end
    end
  RUBY
  
  say "✓ RSpec configured", :green
end

say "✓ RSpec gems added (will be configured after bundle)", :green
