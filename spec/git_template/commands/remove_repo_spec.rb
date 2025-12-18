require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'ostruct'

# Create a test implementation that bypasses Thor DSL
class TestRemoveRepoCommand
  # Include the actual implementation logic without Thor DSL
  def remove_repo(remote_url = nil)
    execute_with_error_handling("remove_repo", options) do
      log_command_execution("remove_repo", [remote_url], options)
      setup_environment(options)
      
      # Validate remote URL is provided
      unless remote_url
        result = GitTemplate::Models::Result::IterateCommandResult.new(
          success: false,
          operation: "remove_repo",
          error_message: "Remote URL is required for remove-repo command"
        )
        puts result.format_output(options[:format], options)
        return result
      end
      
      # Execute repository removal
      result = perform_remove_repo(remote_url, options)
      
      # Format and display output
      puts result.format_output(options[:format], options)
      
      result
    end
  end
  
  def perform_remove_repo(remote_url, options)
    begin
      # Find submodule path for this URL
      submodule_path = find_submodule_path(remote_url)
      unless submodule_path
        return GitTemplate::Models::Result::IterateCommandResult.new(
          success: false,
          operation: "remove_repo",
          error_message: "No submodule found with URL #{remote_url}"
        )
      end
      
      # Check for unpushed changes unless force is enabled
      unless options[:force]
        unpushed_changes = check_unpushed_changes(submodule_path)
        if unpushed_changes
          return GitTemplate::Models::Result::IterateCommandResult.new(
            success: false,
            operation: "remove_repo",
            error_message: "Submodule has unpushed changes. Use --force to override or push changes first."
          )
        end
      end
      
      # Extract repo name from URL for templated folder (same logic as recreate-repo)
      repo_name = File.basename(remote_url, '.git')
      templated_path = "templated/#{repo_name}"
      
      # Remove submodule
      remove_submodule(submodule_path)
      
      # Remove templated folder if it exists
      removed_templated = false
      if Dir.exist?(templated_path)
        FileUtils.rm_rf(templated_path)
        removed_templated = true
      end
      
      # Return success
      GitTemplate::Models::Result::IterateCommandResult.new(
        success: true,
        operation: "remove_repo",
        data: { 
          message: "Repository removal completed successfully",
          removed_submodule_path: submodule_path,
          removed_templated_path: removed_templated ? templated_path : nil,
          remote_url: remote_url
        }
      )
      
    rescue => e
      # Return error result object
      GitTemplate::Models::Result::IterateCommandResult.new(
        success: false,
        operation: "remove_repo",
        error_message: e.message,
        error_type: e.class.name
      )
    end
  end
  
  # Mock methods that would be provided by the base CLI class
  def execute_with_error_handling(operation, options)
    yield
  rescue => e
    GitTemplate::Models::Result::IterateCommandResult.new(
      success: false,
      operation: operation,
      error_message: e.message,
      error_type: e.class.name
    )
  end
  
  def log_command_execution(command, args, options)
    # Mock logging
  end
  
  def setup_environment(options)
    # Mock environment setup
  end
  
  def find_submodule_path(remote_url)
    # Mock implementation - will be overridden in tests
    nil
  end
  
  def check_unpushed_changes(submodule_path)
    # Mock implementation - will be overridden in tests
    false
  end
  
  def remove_submodule(submodule_path)
    # Mock implementation - will be overridden in tests
    true
  end
  
  def options
    @options ||= {}
  end
  
  def options=(opts)
    @options = opts
  end
end

RSpec.describe TestRemoveRepoCommand do
  
  let(:cli) { TestRemoveRepoCommand.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:remote_url) { "https://github.com/example/test-repo.git" }
  let(:submodule_path) { "examples/test-repo" }
  
  before do
    # Set up temporary directory as working directory
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)
    
    # Initialize git repo
    `git init`
    `git config user.email "test@example.com"`
    `git config user.name "Test User"`
    
    cli.options = {
      format: 'detailed',
      verbose: false,
      debug: false,
      force: false
    }
  end
  
  after do
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(temp_dir)
  end

  describe "#remove_repo" do
    context "when no remote URL is provided" do
      it "fails with appropriate error message" do
        result = cli.remove_repo(nil)
        
        expect(result.success).to be false
        expect(result.error_message).to eq("Remote URL is required for remove-repo command")
        expect(result.operation).to eq("remove_repo")
      end
    end

    context "when submodule does not exist" do
      it "fails when no submodule with URL is found" do
        # Mock find_submodule_path to return nil
        allow(cli).to receive(:find_submodule_path).with(remote_url).and_return(nil)
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be false
        expect(result.error_message).to include("No submodule found with URL")
      end
    end

    context "when submodule has unpushed changes" do
      before do
        # Mock successful submodule finding
        allow(cli).to receive(:find_submodule_path).with(remote_url).and_return(submodule_path)
      end

      it "fails when submodule has unpushed changes and force is not enabled" do
        # Mock unpushed changes check to return true
        allow(cli).to receive(:check_unpushed_changes).with(submodule_path).and_return(true)
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be false
        expect(result.error_message).to include("unpushed changes")
        expect(result.error_message).to include("Use --force")
      end

      it "succeeds when submodule has unpushed changes but force is enabled" do
        cli.options[:force] = true
        
        # Mock unpushed changes check to return true
        allow(cli).to receive(:check_unpushed_changes).with(submodule_path).and_return(true)
        
        # Mock successful removal
        allow(cli).to receive(:remove_submodule).with(submodule_path).and_return(true)
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be true
        expect(result.operation).to eq("remove_repo")
      end
    end

    context "when submodule removal fails" do
      before do
        # Mock successful preliminary checks
        allow(cli).to receive(:find_submodule_path).with(remote_url).and_return(submodule_path)
        allow(cli).to receive(:check_unpushed_changes).with(submodule_path).and_return(false)
      end

      it "fails when submodule removal throws an error" do
        # Mock removal failure
        allow(cli).to receive(:remove_submodule).and_raise(StandardError.new("Failed to remove submodule"))
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be false
        expect(result.error_message).to include("Failed to remove submodule")
      end
    end

    context "when removal succeeds" do
      let(:templated_path) { "templated/test-repo" }
      
      before do
        # Mock successful preliminary checks
        allow(cli).to receive(:find_submodule_path).with(remote_url).and_return(submodule_path)
        allow(cli).to receive(:check_unpushed_changes).with(submodule_path).and_return(false)
        allow(cli).to receive(:remove_submodule).with(submodule_path).and_return(true)
      end

      it "succeeds and removes both submodule and templated folder" do
        # Create templated folder
        FileUtils.mkdir_p(templated_path)
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be true
        expect(result.operation).to eq("remove_repo")
        expect(result.data[:message]).to include("Repository removal completed successfully")
        expect(result.data[:removed_submodule_path]).to eq(submodule_path)
        expect(result.data[:removed_templated_path]).to eq(templated_path)
        expect(result.data[:remote_url]).to eq(remote_url)
      end

      it "succeeds when templated folder does not exist" do
        # Don't create templated folder
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be true
        expect(result.operation).to eq("remove_repo")
        expect(result.data[:message]).to include("Repository removal completed successfully")
        expect(result.data[:removed_submodule_path]).to eq(submodule_path)
        expect(result.data[:removed_templated_path]).to be_nil
        expect(result.data[:remote_url]).to eq(remote_url)
      end
    end
  end

  describe "edge cases" do
    context "when force option is enabled" do
      before do
        cli.options[:force] = true
      end

      it "bypasses unpushed changes check" do
        allow(cli).to receive(:find_submodule_path).with(remote_url).and_return(submodule_path)
        allow(cli).to receive(:check_unpushed_changes).with(submodule_path).and_return(true)
        allow(cli).to receive(:remove_submodule).with(submodule_path).and_return(true)
        
        result = cli.remove_repo(remote_url)
        
        expect(result.success).to be true
        expect(cli.options[:force]).to be true
      end
    end
  end
end