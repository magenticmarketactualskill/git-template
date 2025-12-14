# TemplateLifecycle Design Document

## Overview

The TemplateLifecycle class provides a structured, object-oriented approach to managing Rails application template creation. It replaces the current monolithic template.rb approach with a modular, extensible system that organizes template operations into phases, manages user configuration, handles dependencies, and provides clear execution feedback.

The system introduces a standardized folder structure with a 'template' directory within the Rails application structure, containing phase-named subdirectories that organize template modules logically. This follows Rails conventions by placing template-related data under the template folder within the application, addressing the current organizational issues where template modules are scattered in the root directory while providing a clear, extensible structure for future development.

## Architecture

The TemplateLifecycle system follows a layered architecture with standardized folder organization:

```
Rails Application/
├── app/
├── config/
├── db/
├── lib/
├── template/                          # Standard template directory (Rails convention)
│   ├── platform/                      # Phase 1: Platform setup modules
│   │   ├── ruby_version.rb
│   │   ├── rails_config.rb
│   │   └── database.rb
│   ├── infrastructure/                # Phase 2: Infrastructure modules
│   │   ├── gems.rb
│   │   ├── redis.rb
│   │   └── solid_stack.rb
│   ├── frontend/                      # Phase 3: Frontend modules
│   │   ├── vite.rb
│   │   ├── tailwind.rb
│   │   └── inertia.rb
│   ├── testing/                       # Phase 4: Testing modules
│   │   ├── rspec.rb
│   │   └── cucumber.rb
│   ├── security/                      # Phase 5: Security modules
│   │   ├── authorization.rb
│   │   └── security_gems.rb
│   ├── data_flow/                     # Phase 6: Data flow modules
│   │   └── active_data_flow.rb
│   └── application/                   # Phase 7: Application modules
│       ├── models.rb
│       ├── controllers.rb
│       ├── views.rb
│       ├── routes.rb
│       └── admin.rb
├── template.rb                       # Main template entry point
└── other Rails files...
```

System Architecture:

```
┌─────────────────────────────────────┐
│           Template Entry            │
│         (template.rb)               │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│        TemplateLifecycle            │
│      (Main Orchestrator)            │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Phase Manager               │
│    (Organizes execution flow)       │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│       Module Registry               │
│   (Discovers and manages modules)   │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Configuration Manager          │
│   (Handles user preferences)        │
└─────────────────────────────────────┘
```

## Components and Interfaces

### TemplateLifecycle (Main Class)

The primary orchestrator that coordinates the entire template creation process.

**Public Interface:**
```ruby
class TemplateLifecycle
  def initialize(template_context, template_root: "template")
  def execute
  def add_phase(phase)
  def configure_user_preferences
  def current_configuration
  def template_root_path
end
```

**Responsibilities:**
- Initialize and coordinate all subsystems
- Execute the complete template lifecycle
- Provide access to configuration and phase management
- Handle top-level error management and reporting
- Manage the standardized template folder structure

### Phase

Represents a logical grouping of related template modules with execution order and dependencies.

**Public Interface:**
```ruby
class Phase
  def initialize(name, description, order: 0, folder_name: nil)
  def add_module(module_path, conditions: nil)
  def execute(context, config)
  def dependencies_satisfied?(config)
  def should_execute?(config)
  def folder_path
end
```

**Responsibilities:**
- Group related template modules within phase-specific folders
- Manage execution conditions and dependencies
- Execute all modules within the phase
- Provide progress feedback during execution
- Map to standardized folder structure

### ModuleRegistry

Discovers, validates, and manages template modules using the standardized folder structure.

**Public Interface:**
```ruby
class ModuleRegistry
  def initialize(template_root = "template")
  def discover_modules
  def register_module(path, metadata = {})
  def get_module(path)
  def validate_module(path)
  def scan_phase_folders
  def resolve_module_path(phase, module_name)
end
```

**Responsibilities:**
- Auto-discover template modules in the standardized folder structure
- Map folder names to template phases automatically
- Validate module structure and dependencies
- Provide module metadata and path resolution
- Support both legacy flat structure and new organized structure

### ConfigurationManager

Handles user preference collection, validation, and storage.

**Public Interface:**
```ruby
class ConfigurationManager
  def initialize(template_context)
  def collect_preferences
  def validate_configuration
  def get(key, default = nil)
  def set(key, value)
  def to_hash
end
```

**Responsibilities:**
- Present configuration questions to users
- Validate user input and provide defaults
- Store configuration for access throughout template execution
- Support extensible configuration options

## Data Models

### Configuration Schema

```ruby
{
  use_redis: boolean,
  use_active_data_flow: boolean,
  use_docker: boolean,
  generate_sample_models: boolean,
  setup_admin: boolean,
  # Extensible for future options
}
```

### Phase Definition Schema

```ruby
{
  name: string,
  description: string,
  order: integer,
  folder_name: string,
  modules: [
    {
      path: string,
      conditions: hash,
      dependencies: array
    }
  ]
}
```

### Module Metadata Schema

```ruby
{
  path: string,
  name: string,
  description: string,
  dependencies: array,
  conditions: hash,
  phase: string,
  folder_path: string
}
```

### Folder Structure Mapping

```ruby
{
  "platform" => {
    phase_name: "Platform Setup",
    order: 1,
    description: "Ruby version, Rails configuration, database setup"
  },
  "infrastructure" => {
    phase_name: "Infrastructure Setup", 
    order: 2,
    description: "Gems, Redis, Solid Stack, deployment"
  },
  "frontend" => {
    phase_name: "Frontend Setup",
    order: 3, 
    description: "Vite, Tailwind, Inertia, Juris.js"
  },
  "testing" => {
    phase_name: "Testing Setup",
    order: 4,
    description: "RSpec, Cucumber, testing frameworks"
  },
  "security" => {
    phase_name: "Security Setup",
    order: 5,
    description: "Authorization, security gems"
  },
  "data_flow" => {
    phase_name: "Data Flow Setup", 
    order: 6,
    description: "ActiveDataFlow integration"
  },
  "application" => {
    phase_name: "Application Features",
    order: 7,
    description: "Models, controllers, views, routes, admin"
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*
Property 1: System initialization loads all available components
*For any* TemplateLifecycle system initialization, the system should discover and load all available template phases and modules from the standardized template folder structure
**Validates: Requirements 1.1**

Property 2: Complete template orchestration
*For any* Rails template execution, the TemplateLifecycle should execute all applicable phases and modules according to configuration and dependencies
**Validates: Requirements 1.2, 3.3**

Property 3: Execution summary completeness
*For any* completed template execution, the summary should contain all applied modules and the configuration that was used
**Validates: Requirements 1.3, 5.5**

Property 4: Graceful error handling
*For any* error that occurs during template execution, the system should handle it gracefully and provide meaningful error messages without crashing
**Validates: Requirements 1.4**

Property 5: Execution ordering consistency
*For any* set of phases and modules with dependencies and order specifications, the execution should respect both dependency requirements and explicit ordering
**Validates: Requirements 1.5, 3.2, 3.5, 4.5**

Property 6: Configuration collection completeness
*For any* template startup, the system should prompt users for all defined configuration preferences
**Validates: Requirements 2.1**

Property 7: Configuration validation and retry
*For any* user configuration input, the system should validate the values and reject invalid input while requesting valid values
**Validates: Requirements 2.2, 2.3**

Property 8: Configuration persistence and access
*For any* configuration that is collected and stored, it should remain accessible throughout the entire template execution process
**Validates: Requirements 2.4, 2.5**

Property 9: Phase organization consistency
*For any* set of template modules, they should be properly organized into their designated logical phase groupings
**Validates: Requirements 3.1**

Property 10: Dependency validation and enforcement
*For any* modules with dependencies, the system should validate that dependencies are satisfied before execution and prevent execution with appropriate error messages when dependencies are missing
**Validates: Requirements 4.1, 4.2**

Property 11: Conditional module execution
*For any* modules with execution conditions based on user configuration, the system should correctly evaluate those conditions and skip modules that should not be executed
**Validates: Requirements 4.3, 4.4**

Property 12: Template folder structure compliance
*For any* TemplateLifecycle system initialization, the system should use the 'template' folder within the Rails application as the standard location and organize modules in phase-named folders
**Validates: Requirements 6.1, 6.2**

Property 13: Automatic folder-to-phase mapping
*For any* folder structure within the template directory, the system should automatically map folder names to template phases and resolve module paths correctly
**Validates: Requirements 6.3, 6.5**

Property 14: Extensible folder structure
*For any* new phase folders added to the template directory, the system should recognize and integrate them into the execution flow
**Validates: Requirements 6.4**

Property 15: Auto-discovery and integration
*For any* new template modules or phases added to the system, they should be automatically discovered and integrated into the execution flow
**Validates: Requirements 7.1, 7.2**

Property 16: Metadata-driven behavior
*For any* module metadata provided (dependencies, conditions, ordering), the system should use that metadata correctly for dependency resolution and execution ordering
**Validates: Requirements 7.3**

Property 17: Configuration extensibility
*For any* new configuration options added to the system, they should be properly collected, validated, and made available throughout the template process
**Validates: Requirements 7.4**

## Error Handling

The TemplateLifecycle system implements comprehensive error handling at multiple levels:

### Module-Level Errors
- Invalid module syntax or structure
- Missing module dependencies
- Module execution failures
- File system access errors
- Template folder structure violations

### Phase-Level Errors
- Phase dependency violations
- Configuration-based phase skipping
- Phase ordering conflicts
- Missing phase folders

### System-Level Errors
- Configuration validation failures
- Template context initialization errors
- Critical dependency missing errors
- Template folder structure not found

### Error Recovery Strategies
- Graceful degradation when non-critical modules fail
- Clear error messages with actionable guidance
- Rollback capabilities for failed operations
- Continuation options for recoverable errors
- Automatic fallback to legacy folder structure when needed

## Testing Strategy

The TemplateLifecycle system will use a dual testing approach combining unit tests and property-based tests to ensure comprehensive coverage and correctness.

### Unit Testing Approach

Unit tests will focus on:
- Specific examples of configuration scenarios
- Edge cases like empty template directories or malformed configuration
- Integration points between components (TemplateLifecycle ↔ Phase, Phase ↔ ModuleRegistry)
- Error conditions and recovery scenarios
- Mock Rails template context interactions
- Folder structure migration scenarios (legacy to new structure)

Unit tests provide concrete examples that demonstrate correct behavior and catch specific bugs in implementation details.

### Property-Based Testing Approach

Property-based tests will verify universal properties using **rspec-quickcheck** (Ruby) as the property-based testing library. Each property-based test will run a minimum of 100 iterations to ensure thorough coverage of the input space.

Property-based tests will focus on:
- System behavior across all valid configuration combinations
- Module discovery and loading across different filesystem layouts
- Execution ordering with various dependency graphs
- Error handling across different failure scenarios
- Configuration validation with diverse input types
- Folder structure compliance across different template organizations

Each property-based test will be tagged with a comment explicitly referencing the correctness property from this design document using the format: **Feature: template-lifecycle, Property {number}: {property_text}**

### Testing Requirements

- Unit tests and property tests are complementary and both MUST be included
- Property-based tests MUST be configured to run a minimum of 100 iterations
- Each correctness property MUST be implemented by a SINGLE property-based test
- Each property-based test MUST be tagged with the exact format specified above
- Tests should focus on core functional logic and important edge cases
- Both testing approaches together provide comprehensive coverage: unit tests catch concrete bugs, property tests verify general correctness