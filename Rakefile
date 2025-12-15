# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # RSpec not available
end

desc 'Run syntax checks on all Ruby files'
task :syntax do
  files = Dir['lib/**/*.rb', 'exe/*', '*.gemspec']
  files.each do |file|
    sh "ruby -c #{file}"
  end
end

desc 'Build and validate gem'
task :validate_gem do
  sh 'gem build submoduler.gemspec'
  puts '✓ Gem built successfully'
end

desc 'Test CLI functionality'
task :test_cli do
  puts 'Testing CLI functionality...'
  
  # Test version
  sh 'ruby -I lib exe/submoduler --version'
  
  # Test help
  sh 'ruby -I lib exe/submoduler help'
  
  # Test status
  sh 'ruby -I lib exe/submoduler status'
  
  puts '✓ CLI tests passed'
end

desc 'Run all validation tasks'
task validate: [:syntax, :validate_gem, :test_cli]

task default: :validate