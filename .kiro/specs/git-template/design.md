# Design Document

## Overview

The git-template gem will package the existing Rails application template system with TemplateLifecycle management into a distributable Ruby gem. The design preserves all existing functionality while adding proper gem structure, CLI interface, and distribution capabilities. The gem will serve as both a library for programmatic use and a command-line tool for direct template application.

## Architecture

The git-template gem follows a layered architecture:

```
┌─────────────────────────────────────┐
│           CLI Interface             │
│        (bin/git-template)           │
├─────────────────────────────────────┤
│         Gem Entry Point             │
│      (lib/git_template.rb)          │
├─────────────────────────────────────┤
│       Template System Core          │
│    (existing TemplateLifecycle)     │
├─────────────────────────────────────┤
│        Template Modules             │
│   (template/ directory structure)   │
└─────────────────────────────────────┘
```

The architecture maintains separation between:
- **CLI Layer**: Command-line interface for user interaction
- **Library Layer**: Programmatic API for gem usage
- **Core Layer**: Existing TemplateLifecycle system
- **Template Layer**: All template modules and phases

## Components and Interfaces

### 1. Gem Structure
```
git-template/
├── lib/
│   ├── git_template.rb              # Main gem entry point
│   ├── git_template/
│   │   ├── version.rb               # Version management
│   │   ├── cli.rb                   # Command-line interface
│   │   ├── template_resolver.rb     # Template path resolution
│   │   └── gem_template_runner.rb   # Gem-aware template runner
│   ├── template_lifecycle.rb        # Existing lifecycle system
│   ├── configuration_manager.rb     # Existing config management
│   ├── module_registry.rb           # Existing module registry
│   ├── phase.rb                     # Existing phase management
│   └── template_lifecycle_errors.rb # Existing error handling
├── template/                        # All existing template modules
├── bin/
│   └── git-template                 # CLI executable
├── spec/                            # Test suite
├── examples/                        # Usage examples
├── git-template.gemspec             # Gem specification
├── README.md                        # Documentation
├── CHANGELOG.md                     # Version history
└── LICENSE                          # License file
```

### 2. CLI Interface (GitTemplate::CLI)
```ruby
class GitTemplate::CLI
  def self.start(args)
    # Parse command-line arguments
    # Route to appropriate action
  end
  
  def apply(template_path = nil)
    # Apply template to current or new Rails app
  end
  
  def list
    # List available templates
  end
  
  def version
    # Display gem version
  end
end
```

### 3. Template Resolver (GitTemplate::TemplateResolver)
```ruby
class GitTemplate::TemplateResolver
  def self.resolve_template_path(template_name = nil)
    # Resolve template path within gem
    # Support both bundled and external templates
  end
  
  def self.gem_template_path
    # Return path to bundled template.rb
  end
end
```

### 4. Gem Template Runner (GitTemplate::GemTemplateRunner)
```ruby
class GitTemplate::GemTemplateRunner
  def initialize(rails_app_generator)
    # Initialize with Rails app generator context
  end
  
  def run_template(template_path = nil)
    # Execute template with proper gem context
    # Ensure all gem paths are resolved correctly
  end
end
```

## Data Models

### 1. Version Management
```ruby
module GitTemplate
  VERSION = "1.0.0"
end
```

### 2. Template Configuration
The gem preserves all existing configuration structures from the TemplateLifecycle system:
- User configuration collection
- Module dependency resolution
- Phase execution ordering
- Conditional module execution

### 3. Gem Metadata
```ruby
# git-template.gemspec
Gem::Specification.new do |spec|
  spec.name          = "git-template"
  spec.version       = GitTemplate::VERSION
  spec.authors       = ["Author Name"]
  spec.email         = ["author@example.com"]
  spec.summary       = "Rails application template with lifecycle management"
  spec.description   = "A Ruby gem for managing Rails application templates..."
  spec.homepage      = "https://github.com/username/git-template"
  spec.license       = "MIT"
  
  spec.required_ruby_version = ">= 3.0.0"
  spec.add_dependency "rails", ">= 7.0"
  
  spec.files         = Dir["lib/**/*", "template/**/*", "bin/*", "*.md"]
  spec.bindir        = "bin"
  spec.executables   = ["git-template"]
  spec.require_paths = ["lib"]
end
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*
Based on the prework analysis, I've identified several properties that can be tested to ensure the gem functions correctly:

**Property 1: Gem component accessibility**
*For any* installed git-template gem, requiring the gem should make all template modules and TemplateLifecycle components accessible and instantiable
**Validates: Requirements 1.3**

**Property 2: Dependency loading completeness**
*For any* git-template gem installation, requiring the main gem file should define all expected constants, classes, and modules
**Validates: Requirements 1.4**

**Property 3: Template resolution functionality**
*For any* Rails application context, the git-template system should be able to resolve and execute the bundled template
**Validates: Requirements 2.2**

**Property 4: CLI command execution**
*For any* valid CLI invocation, the git-template command should execute successfully and apply the template to the target application
**Validates: Requirements 2.3**

**Property 5: Help information display**
*For any* CLI help request, the system should display usage instructions containing all available commands and options
**Validates: Requirements 2.4**

**Property 6: Success message display**
*For any* successful template application, the system should output completion confirmation and next steps information
**Validates: Requirements 2.5**

**Property 7: Gem structure compliance**
*For any* git-template gem package, the directory structure should follow Ruby gem conventions with lib/, bin/, and spec/ directories in correct locations
**Validates: Requirements 3.1**

**Property 8: Gemspec metadata completeness**
*For any* git-template gemspec, it should contain all required metadata fields including name, version, dependencies, and file specifications
**Validates: Requirements 3.2**

**Property 9: Template file inclusion**
*For any* packaged git-template gem, all template modules and lifecycle management files should be included in the gem package
**Validates: Requirements 3.3**

**Property 10: TemplateLifecycle functionality preservation**
*For any* template execution through the gem, the TemplateLifecycle should behave identically to the original standalone system
**Validates: Requirements 4.1**

**Property 11: Phase execution order preservation**
*For any* template execution, phases should execute in the same sequential order as the original system
**Validates: Requirements 4.2**

**Property 12: Configuration option preservation**
*For any* user configuration collection, all original configuration options should be available and functional
**Validates: Requirements 4.3**

**Property 13: Module inclusion completeness**
*For any* template execution, all original template modules should be accessible and executable
**Validates: Requirements 4.4**

**Property 14: Application structure generation**
*For any* completed template execution, the generated application structure should match the expected output from the original system
**Validates: Requirements 4.5**

**Property 15: Semantic version format compliance**
*For any* git-template version number, it should follow semantic versioning format (MAJOR.MINOR.PATCH)
**Validates: Requirements 5.1**

**Property 16: Dependency declaration completeness**
*For any* git-template gemspec, all required runtime dependencies should be properly declared with appropriate version constraints
**Validates: Requirements 7.1**

**Property 17: Ruby version requirement specification**
*For any* git-template gemspec, minimum Ruby version requirements should be explicitly specified
**Validates: Requirements 7.2**

**Property 18: Rails version requirement specification**
*For any* git-template gemspec, compatible Rails version ranges should be declared in dependencies
**Validates: Requirements 7.3**

**Property 19: Dependency error handling**
*For any* dependency conflict scenario, the system should provide clear error messages with resolution guidance
**Validates: Requirements 7.4**

## Error Handling

The gem will implement comprehensive error handling:

### 1. Installation Errors
- Missing Ruby/Rails version requirements
- Dependency resolution failures
- File permission issues

### 2. Template Execution Errors
- Invalid Rails application context
- Missing template files
- Configuration validation failures
- Module execution failures

### 3. CLI Errors
- Invalid command arguments
- Missing target application
- Permission denied scenarios

### 4. Error Recovery
- Graceful degradation when optional modules fail
- Clear error messages with actionable guidance
- Rollback capabilities for partial failures

## Testing Strategy

The git-template gem will use a dual testing approach combining unit tests and property-based tests:

### Unit Testing
- **Framework**: RSpec for Ruby testing
- **Coverage**: Specific examples, edge cases, and integration points
- **Focus Areas**:
  - CLI command parsing and execution
  - Template resolution and loading
  - Gemspec validation
  - Error handling scenarios

### Property-Based Testing
- **Framework**: RSpec with rspec-quickcheck for property-based testing
- **Configuration**: Minimum 100 iterations per property test
- **Property Test Requirements**:
  - Each property-based test must be tagged with a comment referencing the design document property
  - Tag format: `**Feature: git-template, Property {number}: {property_text}**`
  - Each correctness property must be implemented by a single property-based test
  - Tests should focus on universal behaviors that hold across all valid inputs

### Test Organization
- Unit tests verify specific examples and edge cases work correctly
- Property-based tests verify universal properties hold across all inputs
- Both types of tests are valuable and complement each other
- Tests will be co-located with source files using `.spec.rb` suffix
- Integration tests will verify end-to-end template application scenarios

### Test Coverage Requirements
- All public API methods must have unit test coverage
- All correctness properties must have corresponding property-based tests
- CLI commands must have both unit and integration test coverage
- Error handling paths must be tested with appropriate scenarios