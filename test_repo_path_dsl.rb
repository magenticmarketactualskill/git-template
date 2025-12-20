#!/usr/bin/env ruby

# Test script to verify repo_path DSL functionality
lib_path = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(lib_path)

require 'git_template/generator/base'

# Load the example generator
load 'templated/examples/rails8-simple/.git_template/template_part/gem_file_generator_0001.rb'

puts "=== repo_path DSL Test ==="
puts
puts "Class-level repo_path: #{GemFileGenerator0001.repo_path.inspect}"
puts "Class-level golden_text length: #{GemFileGenerator0001.golden_text&.length} chars"
puts

# Test instance access
class TestConfig
  attr_reader :id
  def initialize(id = 'test-123')
    @id = id
  end
end

config = TestConfig.new
generator = GemFileGenerator0001.new(config)

puts "Instance repo_path: #{generator.repo_path.inspect}"
puts "Instance golden_text length: #{generator.golden_text&.length} chars"
puts
puts "=== Test Complete ==="
