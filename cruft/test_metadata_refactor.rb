#!/usr/bin/env ruby

# Quick test script to verify the refactored metadata system
require_relative 'lib/git_template/generator/base'

# Mock config class for testing
class TestConfig
  attr_reader :id
  
  def initialize(id = 'test-config-123')
    @id = id
  end
  
  def to_h
    { id: @id, type: 'test' }
  end
end

# Test generator class
class TestGenerator < GitTemplate::Generators::Base
  golden_text "This is test content"
  
  def generate
    puts "=== METADATA REFACTOR TEST ==="
    puts
    
    puts "Available methods:"
    puts self.methods.grep(/metadata/).sort
    puts
    
    puts "1. Standard metadata comment:"
    puts metadata_comment
    puts
    
    puts "2. Compact metadata comment:"
    puts metadata_comment(format: :compact)
    puts
    
    puts "3. Detailed metadata comment:"
    puts metadata_comment(format: :detailed)
    puts
    
    puts "4. Generation fingerprint:"
    puts metadata_fingerprint
    puts
    
    puts "5. Metadata JSON (pretty):"
    puts metadata_json(pretty: true)
    puts
    
    puts "=== TEST COMPLETE ==="
  end
  
  private
  
  def custom_metadata
    {
      test_mode: true,
      test_timestamp: Time.now.to_i,
      custom_field: "This is custom metadata"
    }
  end
end

# Run the test
config = TestConfig.new
generator = TestGenerator.new(config)
generator.generate