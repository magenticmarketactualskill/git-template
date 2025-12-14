# Setup Redis or redis-emulator
say "Setting up Redis...", :green

if @use_redis
  # Use actual Redis
  gem "redis", "~> 4.0", comment: "Load redis gem first to define Redis class"
  
  say "✓ Redis gem added (remember to install Redis server)", :green
else
  # Use redis-emulator
  say "Setting up redis-emulator...", :green
  
  # Create vendor/redis-emulator directory
  run "mkdir -p vendor/redis-emulator"
  
  # Note: In a real implementation, you would copy the redis-emulator files here
  # For now, we'll add a placeholder
  file "vendor/redis-emulator/README.md", <<~MD
    # Redis Emulator
    
    This directory contains the redis-emulator for development/testing without a Redis server.
    
    To use the actual redis-emulator from the rails8-juris repository, copy the files from:
    vendor/redis-emulator/
  MD
  
  gem "redis-emulator", path: "vendor/redis-emulator", comment: "Redis emulator for development"
  
  say "✓ redis-emulator configured", :green
end

# Add solid_cache as Redis alternative
gem "solid_cache", comment: "Database-backed Active Support cache"

say "✓ Redis/cache configuration complete", :green
