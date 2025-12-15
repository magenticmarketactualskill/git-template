# Add core gems and dependencies
say "Adding core gems...", :green

# Ensure Rails 8.1+ is specified
gem "rails", "~> 8.1.1"

# Asset pipeline
gem "propshaft", comment: "The modern asset pipeline for Rails"

# Web server
gem "puma", "~> 5.0", comment: "Use the Puma web server"

# Database
gem "sqlite3", "~> 2.1", comment: "Use sqlite3 as the database for Active Record"

# Frontend
gem "importmap-rails", comment: "Use JavaScript with ESM import maps"
gem "turbo-rails", comment: "Hotwire's SPA-like page accelerator"
gem "stimulus-rails", comment: "Hotwire's modest JavaScript framework"
gem "tailwindcss-rails", comment: "Use Tailwind CSS"

# Inertia.js
gem "inertia_rails", "~> 3.0", comment: "Inertia.js adapter for Rails"

# Active Storage
gem "image_processing", "~> 1.2", comment: "Use Active Storage variants"

# HTTP asset caching/compression
gem "thruster", require: false, comment: "Add HTTP asset caching/compression and X-Sendfile acceleration to Puma"

# Development and test gems
gem_group :development, :test do
  gem "debug", platforms: %i[ mri windows ], comment: "See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem"
  gem "bundler-audit", require: false, comment: "Audits gems for known security defects"
  gem "brakeman", require: false, comment: "Static analysis for security vulnerabilities"
end

# Development gems
gem_group :development do
  gem "web-console", comment: "Use console on exceptions pages"
end

# Code quality
gem "rubocop-rails-omakase", require: false, group: :development, comment: "Omakase Ruby styling"

say "✓ Core gems added", :green
