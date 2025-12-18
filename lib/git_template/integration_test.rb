# Integration Test for Status Command System
#
# This file provides basic integration testing to verify that all components
# work together correctly. It's designed to be run manually or as part of
# a simple test suite.

require_relative 'commands/status_command'
require_relative 'commands/clone_command'
require_relative 'commands/iterate_command'
require_relative 'commands/update_command'
require_relative 'commands/push_command'

module GitTemplate
  class IntegrationTest
    def initialize
      @test_results = []
      @temp_dirs = []
    end

    def run_all_tests
      puts "🧪 Running Git Template Integration Tests"
      puts "=" * 50
      
      begin
        test_status_command
        test_folder_analyzer
        test_template_configuration
        test_comparison_result
        
        puts "\n" + "=" * 50
        puts "📊 Test Results Summary"
        puts "=" * 50
        
        passed = @test_results.count { |r| r[:passed] }
        total = @test_results.length
        
        puts "Total tests: #{total}"
        puts "Passed: #{passed}"
        puts "Failed: #{total - passed}"
        
        if passed == total
          puts "\n✅ All tests passed!"
          return true
        else
          puts "\n❌ Some tests failed:"
          @test_results.select { |r| !r[:passed] }.each do |result|
            puts "  - #{result[:name]}: #{result[:error]}"
          end
          return false
        end
        
      ensure
        cleanup_temp_directories
      end
    end

    private

    def test_status_command
      test_case("Status Command Basic Functionality") do
        # Create a temporary directory structure for testing
        test_dir = create_temp_directory("status_test")
        
        # Test with non-existent directory
        command = Commands::StatusCommand.new
        result = command.execute("/non/existent/path")
        
        unless result[:success] == false
          raise "Expected status command to fail for non-existent path"
        end
        
        # Test with existing directory (no git, no template)
        result = command.execute(test_dir)
        
        unless result[:success] == true
          raise "Expected status command to succeed for existing directory"
        end
        
        # Verify analysis data structure
        analysis_data = result[:analysis_data]
        unless analysis_data && analysis_data[:folder_analysis]
          raise "Expected analysis data to contain folder_analysis"
        end
        
        folder_analysis = analysis_data[:folder_analysis]
        unless folder_analysis[:exists] == true
          raise "Expected folder to be marked as existing"
        end
        
        unless folder_analysis[:is_git_repository] == false
          raise "Expected folder to not be marked as git repository"
        end
        
        puts "  ✅ Status command basic functionality works"
      end
    end

    def test_folder_analyzer
      test_case("Folder Analyzer Service") do
        require_relative 'services/folder_analyzer'
        
        analyzer = Services::FolderAnalyzer.new
        test_dir = create_temp_directory("analyzer_test")
        
        # Test basic folder analysis
        analysis = analyzer.analyze_folder(test_dir)
        
        unless analysis.exists
          raise "Expected folder to exist"
        end
        
        unless analysis.is_git_repository == false
          raise "Expected folder to not be git repository"
        end
        
        unless analysis.has_template_configuration == false
          raise "Expected folder to not have template configuration"
        end
        
        # Test with git repository
        Dir.chdir(test_dir) do
          system("git init > /dev/null 2>&1")
        end
        
        analysis = analyzer.analyze_folder(test_dir)
        unless analysis.is_git_repository == true
          raise "Expected folder to be git repository after git init"
        end
        
        puts "  ✅ Folder analyzer works correctly"
      end
    end

    def test_template_configuration
      test_case("Template Configuration Model") do
        require_relative 'models/template_configuration'
        
        test_dir = create_temp_directory("template_config_test")
        git_template_dir = File.join(test_dir, '.git_template')
        FileUtils.mkdir_p(git_template_dir)
        
        # Create basic template.rb
        template_file = File.join(git_template_dir, 'template.rb')
        File.write(template_file, "# Basic template\nsay 'Hello from template'")
        
        config = Models::TemplateConfiguration.new(git_template_dir)
        
        unless config.valid?
          raise "Expected template configuration to be valid"
        end
        
        unless config.has_template_file?
          raise "Expected template configuration to have template file"
        end
        
        unless File.exist?(config.template_file_path)
          raise "Expected template file to exist at specified path"
        end
        
        puts "  ✅ Template configuration model works correctly"
      end
    end

    def test_comparison_result
      test_case("Comparison Result Model") do
        require_relative 'models/result/comparison_result'
        
        # Create two test directories with different content
        source_dir = create_temp_directory("comparison_source")
        target_dir = create_temp_directory("comparison_target")
        
        # Add some files to source
        File.write(File.join(source_dir, 'file1.txt'), 'content1')
        File.write(File.join(source_dir, 'file2.txt'), 'content2')
        
        # Add different files to target
        File.write(File.join(target_dir, 'file2.txt'), 'different_content2')
        File.write(File.join(target_dir, 'file3.txt'), 'content3')
        
        comparison = Models::Result::ComparisonResult.new(source_dir, target_dir)
        
        unless comparison.has_differences?
          raise "Expected comparison to find differences"
        end
        
        unless comparison.added_files.include?('file1.txt')
          raise "Expected file1.txt to be in added files"
        end
        
        unless comparison.modified_files.include?('file2.txt')
          raise "Expected file2.txt to be in modified files"
        end
        
        unless comparison.deleted_files.include?('file3.txt')
          raise "Expected file3.txt to be in deleted files"
        end
        
        puts "  ✅ Comparison result model works correctly"
      end
    end

    def test_case(name)
      begin
        yield
        @test_results << { name: name, passed: true }
      rescue => e
        @test_results << { name: name, passed: false, error: e.message }
        puts "  ❌ #{name} failed: #{e.message}"
      end
    end

    def create_temp_directory(name)
      require 'tmpdir'
      temp_dir = File.join(Dir.tmpdir, "git_template_test_#{name}_#{Time.now.to_i}")
      FileUtils.mkdir_p(temp_dir)
      @temp_dirs << temp_dir
      temp_dir
    end

    def cleanup_temp_directories
      @temp_dirs.each do |dir|
        FileUtils.rm_rf(dir) if File.directory?(dir)
      end
      @temp_dirs.clear
    end
  end
end

# Run tests if this file is executed directly
if __FILE__ == $0
  test_runner = GitTemplate::IntegrationTest.new
  success = test_runner.run_all_tests
  exit(success ? 0 : 1)
end