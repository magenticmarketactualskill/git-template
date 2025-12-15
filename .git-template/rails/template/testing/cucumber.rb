# Setup Cucumber for BDD testing
say "Setting up Cucumber...", :green

# Add Cucumber gems
gem_group :test do
  gem "cucumber-rails", require: false, comment: "Cucumber for Rails"
  gem "capybara", comment: "Integration testing tool"
  gem "selenium-webdriver", comment: "WebDriver for browser automation"
end

# Cucumber will be installed via rails generate cucumber:install in after_bundle
after_bundle do
  # Generate Cucumber configuration
  generate "cucumber:install"
  
  say "✓ Cucumber configured", :green
end

say "✓ Cucumber gems added (will be configured after bundle)", :green
