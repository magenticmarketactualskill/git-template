#!/usr/bin/env ruby

# Simple test to isolate the metadata issue
require 'ostruct'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'git_template/generator/metadata'

class TestClass
  include GitTemplate::Generators::Metadata
  
  def initialize
    @config = OpenStruct.new(id: 'test-123')
  end
  
  def test_method
    puts "Testing metadata_comment method..."
    
    # Test with no parameters
    puts "1. No parameters:"
    puts metadata_comment
    puts
    
    # Test with prefix only
    puts "2. With prefix:"
    puts metadata_comment(prefix: '//')
    puts
    
    # Test with format only
    puts "3. With format:"
    begin
      puts metadata_comment(format: :compact)
    rescue => e
      puts "ERROR: #{e.message}"
      puts "Class: #{e.class}"
    end
    puts
  end
end

test = TestClass.new
test.test_method