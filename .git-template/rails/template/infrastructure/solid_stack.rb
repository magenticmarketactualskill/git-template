# Setup Solid Cache, Solid Queue, and Solid Cable
say "Setting up Solid stack (Cache, Queue, Cable)...", :green

# Solid Queue for background jobs
gem "solid_queue", comment: "Database-backed Active Job backend"

# Solid Cable for Action Cable
gem "solid_cable", comment: "Database-backed Action Cable backend"

# Configure Solid Cache
initializer "solid_cache.rb", <<~RUBY
  # Solid Cache configuration
  # See https://github.com/rails/solid_cache for more information
  
  Rails.application.configure do
    # Use Solid Cache as the cache store
    config.cache_store = :solid_cache_store
  end
RUBY

# Configure Solid Queue
initializer "solid_queue.rb", <<~RUBY
  # Solid Queue configuration
  # See https://github.com/rails/solid_queue for more information
  
  Rails.application.configure do
    # Use Solid Queue as the Active Job backend
    config.active_job.queue_adapter = :solid_queue
  end
RUBY

say "✓ Solid stack configured", :green
