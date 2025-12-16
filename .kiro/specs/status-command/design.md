# Design Document

## Overview

The git-template status command system extends the existing git-template CLI tool with comprehensive lifecycle management capabilities for Rails application templates. The system provides developers with tools to clone applications, check status, iterate on templates, update configurations, and push changes to remote repositories. This design builds upon the existing TemplateLifecycle architecture while adding new command-line interfaces for template development workflow management.

## Architecture

The system follows a modular architecture that integrates with the existing git-template infrastructure:

```
GitTemplate::CLI
├── StatusCommand (new)
├── CloneCommand (new) 
├── IterateCommand (new)
├── UpdateCommand (new)
├── PushCommand (new)
└── Existing commands (apply, version, etc.)
```

### Core Components

1. **Command Layer**: Thor-based CLI commands that handle user input and orchestrate operations
2. **Service Layer**: Business logic services that implement the core functionality
3. **Repository Layer**: File system and git operations abstraction
4. **Status Analysis**: Logic for analyzing folder states and template configurations

## Components and Interfaces

### CLI Commands

#### StatusCommand
- **Purpose**: Analyze and report the status of application folders
- **Interface**: `git-template status FOLDER`
- **Responsibilities**: 
  - Validate folder existence
  - Check for Template_Configuration
  - Verify Git_Repository status
  - Locate corresponding Templated_Folder
  - Generate structured status report

#### CloneCommand  
- **Purpose**: Clone remote repositories for template development
- **Interface**: `git-template clone GIT_URL [TARGET_FOLDER]`
- **Responsibilities**:
  - Validate Git URL format
  - Execute git clone operations
  - Handle authentication and network errors
  - Prevent overwriting existing content

#### IterateCommand
- **Purpose**: Refine templates through iterative comparison
- **Interface**: `git-template iterate FOLDER`
- **Responsibilities**:
  - Preserve Template_Configuration in Templated_Folder
  - Apply current template to generate fresh content
  - Compare generated content with Application_Folder
  - Update template Cleanup_Phase with differences

#### UpdateCommand
- **Purpose**: Process and validate template modifications
- **Interface**: `git-template update FOLDER`
- **Responsibilities**:
  - Validate template structure and syntax
  - Process template configuration changes
  - Ensure template completeness and accuracy

#### PushCommand
- **Purpose**: Push application folders to remote repositories
- **Interface**: `git-template push FOLDER [REMOTE_URL]`
- **Responsibilities**:
  - Verify Git_Repository status
  - Initialize git repository if needed
  - Handle authentication and push operations
  - Provide detailed error reporting

### Service Classes

#### FolderAnalyzer
- **Purpose**: Analyze folder structure and determine status
- **Methods**:
  - `analyze_folder(path)`: Returns comprehensive folder analysis
  - `has_template_configuration?(path)`: Checks for .git_template directory
  - `is_git_repository?(path)`: Verifies .git directory presence
  - `find_templated_folder(path)`: Locates corresponding templated version

#### GitOperations
- **Purpose**: Abstract git command execution
- **Methods**:
  - `clone_repository(url, target_path)`: Clone remote repository
  - `initialize_repository(path)`: Initialize new git repository
  - `push_to_remote(path, remote_url)`: Push changes to remote
  - `get_repository_status(path)`: Get current git status

#### TemplateProcessor
- **Purpose**: Handle template application and comparison
- **Methods**:
  - `apply_template(template_path, target_path)`: Apply template to target
  - `compare_folders(source_path, target_path)`: Generate diff between folders
  - `update_cleanup_phase(template_path, differences)`: Add differences to cleanup

#### StatusReporter
- **Purpose**: Generate formatted status reports
- **Methods**:
  - `generate_report(analysis_data)`: Create structured status output
  - `format_findings(findings)`: Format analysis results for display

## Data Models

### FolderAnalysis
```ruby
class FolderAnalysis
  attr_reader :path, :exists, :is_git_repository, :has_template_configuration,
              :templated_folder_path, :templated_folder_exists, 
              :templated_has_configuration, :analysis_timestamp

  def initialize(path)
    @path = path
    @analysis_timestamp = Time.now
    analyze
  end

  def status_summary
    # Returns hash with all status information
  end
end
```

### TemplateConfiguration
```ruby
class TemplateConfiguration
  attr_reader :path, :template_file, :modules_directory, :files_directory,
              :lifecycle_phases, :cleanup_phase

  def initialize(git_template_path)
    @path = git_template_path
    load_configuration
  end

  def valid?
    # Validates template structure and required files
  end
end
```

### ComparisonResult
```ruby
class ComparisonResult
  attr_reader :added_files, :modified_files, :deleted_files, :differences

  def initialize(source_path, target_path)
    @source_path = source_path
    @target_path = target_path
    perform_comparison
  end

  def has_differences?
    # Returns true if any differences found
  end
end
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*
Property 1: Git clone preserves repository structure
*For any* valid git repository URL and target path, cloning the repository should result in a complete copy with all files, directories, and git history preserved
**Validates: Requirements 1.1, 1.2**

Property 2: Invalid git URLs are handled gracefully
*For any* invalid or inaccessible git URL, the clone operation should fail with a clear error message and not crash the system
**Validates: Requirements 1.3**

Property 3: Existing directories are protected from overwrite
*For any* existing directory with content, attempting to clone into it should preserve the original content and not overwrite it
**Validates: Requirements 1.4**

Property 4: Status command detects template configuration
*For any* folder path, the status command should correctly identify whether a .git_template directory exists in that folder
**Validates: Requirements 2.1**

Property 5: Status command detects git repositories
*For any* folder path, the status command should correctly identify whether the folder is a git repository by checking for .git directory
**Validates: Requirements 2.2**

Property 6: Status command finds templated folders
*For any* application folder, the status command should correctly determine if a corresponding templated folder (in templated/ directory structure) exists
**Validates: Requirements 2.3**

Property 7: Status command checks templated folder configuration
*For any* templated folder that exists, the status command should correctly verify whether it contains template configuration
**Validates: Requirements 2.4**

Property 8: Status output contains all required information
*For any* folder analysis, the status command output should include all findings in a structured, consistent format
**Validates: Requirements 2.5**

Property 9: Template iteration preserves configuration
*For any* templated folder with mixed content, running iterate_template should preserve only the .git_template directory and remove all other content
**Validates: Requirements 3.1**

Property 10: Template application generates content
*For any* valid template configuration, applying the template should generate the expected application content structure
**Validates: Requirements 3.2**

Property 11: Folder comparison detects differences
*For any* two folder structures, the comparison operation should correctly identify all added, modified, and deleted files
**Validates: Requirements 3.3**

Property 12: Differences are added to cleanup phase
*For any* detected differences between folders, those differences should be properly added to the template's cleanup phase configuration
**Validates: Requirements 3.4**

Property 13: Template iteration maintains completeness
*For any* completed template iteration, applying the updated template should produce identical results to the target application (round trip property)
**Validates: Requirements 3.5**

Property 14: Template updates are processed correctly
*For any* template modification, the update command should process the changes and maintain template validity
**Validates: Requirements 4.1**

Property 15: Template validation detects structural issues
*For any* template configuration, the validation process should correctly identify structural problems and configuration errors
**Validates: Requirements 4.2**

Property 16: Updated templates maintain reproduction capability
*For any* updated template, it should still be capable of producing complete and accurate application reproduction
**Validates: Requirements 4.3**

Property 17: Template validation errors are specific
*For any* invalid template configuration, the validation should provide specific, actionable error messages describing the problems
**Validates: Requirements 4.4**

Property 18: Push command verifies git repository status
*For any* folder path, the push command should correctly determine whether the folder is a git repository before attempting to push
**Validates: Requirements 5.1**

Property 19: Successful push operations are confirmed
*For any* successful push operation, the system should provide clear confirmation of the successful synchronization
**Validates: Requirements 5.3**

Property 20: Non-git folders are initialized before push
*For any* folder that is not a git repository, the push command should initialize it as a git repository before pushing
**Validates: Requirements 5.4**

Property 21: Push failures provide detailed errors
*For any* failed push operation, the system should provide detailed error information to help diagnose the problem
**Validates: Requirements 5.5**

## Error Handling

The system implements comprehensive error handling across all operations:

### Input Validation
- **Git URL Validation**: Verify URL format and accessibility before clone operations
- **Path Validation**: Ensure target paths are valid and accessible
- **Template Validation**: Verify template structure and required files exist

### Operation Error Handling
- **Network Errors**: Handle connection timeouts, authentication failures, and network unavailability
- **File System Errors**: Manage permission issues, disk space problems, and path conflicts
- **Git Operation Errors**: Handle repository corruption, merge conflicts, and remote access issues

### Error Reporting
- **Structured Error Messages**: Provide clear, actionable error descriptions
- **Error Codes**: Use consistent error codes for programmatic handling
- **Logging**: Maintain detailed logs for debugging and audit purposes

## Testing Strategy

### Unit Testing
The system will use RSpec for unit testing with focus on:
- Individual command validation and execution
- Service class method behavior
- Error handling scenarios
- File system operation mocking

### Property-Based Testing
The system will use RSpec with the `rspec-parameterized` gem for property-based testing:
- **Minimum 100 iterations** per property test to ensure comprehensive coverage
- **Random data generation** for paths, URLs, and folder structures
- **Property test tagging** using the format: `**Feature: status-command, Property {number}: {property_text}**`
- Each correctness property will be implemented as a single property-based test
- Property tests will verify universal behaviors across all valid inputs

### Integration Testing
- End-to-end command execution testing
- File system integration with temporary directories
- Git operation integration with test repositories

The dual testing approach ensures both specific examples work correctly (unit tests) and general properties hold across all inputs (property tests), providing comprehensive correctness validation.