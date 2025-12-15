# Setup ActiveDataFlow for data transformation
say "Setting up ActiveDataFlow...", :green

# Note: ActiveDataFlow gems reference parent repository paths
# For a standalone template, you would need to either:
# 1. Publish ActiveDataFlow gems to RubyGems
# 2. Use git sources
# 3. Provide local paths

say "Adding ActiveDataFlow gems...", :yellow
say "Note: ActiveDataFlow requires path or git references to the parent repository", :yellow

# Placeholder for ActiveDataFlow gems
# In production, these would reference actual gem sources
comment = "ActiveDataFlow gems - update paths/sources as needed"

gem "active_data_flow-connector-source-active_record", 
    path: "../active_data_flow-connector-source-active_record",
    comment: comment

gem "active_data_flow-connector-sink-active_record",
    path: "../active_data_flow-connector-sink-active_record", 
    comment: comment

gem "active_data_flow-runtime-heartbeat",
    path: "../active_data_flow-runtime-heartbeat",
    comment: comment

# Mount ActiveDataFlow engine
route 'mount ActiveDataFlow::Engine => "/active_data_flow"'

# Create ActiveDataFlow initializer
initializer "active_data_flow.rb", <<~RUBY
  # ActiveDataFlow configuration
  # See ActiveDataFlow documentation for more information
  
  ActiveDataFlow.configure do |config|
    # Configure your data flows here
  end
RUBY

say "✓ ActiveDataFlow configured", :green
say "  Remember to update gem paths/sources in Gemfile", :yellow
