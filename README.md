# git-template

A comprehensive Ruby gem for Rails application template development and execution with dual lifecycle management. Provides both template creation/refinement tools and structured template execution with organized phases.

## Features

### Template Implementation Lifecycle (NEW)
- **Status Analysis**: Check template development status and readiness
- **Repository Cloning**: Clone applications for template development
- **Template Iteration**: Compare and refine templates through iterative development
- **Configuration Management**: Update and validate template configurations
- **Git Integration**: Push template development work to remote repositories

### Template Execution Lifecycle
- **Structured Template Phases**: Organized phases for platform, infrastructure, frontend, testing, security, data flow, and application setup
- **User Configuration Management**: Interactive prompts for customizing template behavior
- **Extensible Module System**: Easy to add new template modules and phases
- **Specialized Phase Architecture**: Content moved from cleanup phases to dedicated specialized phases
- **Example Rails 8 + Juris.js Template**: Modern Rails setup with Vite, Tailwind CSS, and Juris.js frontend framework

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'git-template'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install git-template
```

## Usage

### Template Implementation Lifecycle

The git-template system now provides a complete workflow for developing and refining templates:

#### 1. Clone Applications for Template Development
```bash
# Clone a repository to use as a template base
git-template clone https://github.com/user/rails-app.git

# Clone with template development setup
git-template clone https://github.com/user/rails-app.git --create-template-config
```

#### 2. Check Template Development Status
```bash
# Check status of current folder
git-template status .

# Check status with detailed output
git-template status /path/to/app --format detailed --verbose

# Get JSON output for programmatic use
git-template status . --format json
```

#### 3. Iterate and Refine Templates
```bash
# Iterate on template development
git-template iterate .

# Create templated folder if it doesn't exist
git-template iterate . --create-templated-folder

# Show detailed comparison results
git-template iterate . --detailed-comparison --verbose
```

#### 4. Update Template Configurations
```bash
# Update template with all improvements
git-template update . --all

# Fix common template issues
git-template update . --fix-issues

# Update template metadata
git-template update . --update-metadata
```

#### 5. Push Template Development Work
```bash
# Push to remote repository
git-template push . https://github.com/user/template-repo.git

# Commit changes and push
git-template push . --commit-changes --commit-message "Template improvements"

# Initialize git repo if needed and push
git-template push . --initialize-if-needed
```

#### 5. Generate Template Documentation
```bash
# Convert template.rb to markdown documentation
git-template to_md examples/rails/myapp

# Specify custom output file
git-template to_md examples/rails/myapp --output-file docs/template-guide.md

# Show verbose output during conversion
git-template to_md examples/rails/myapp --verbose
```

### Template Execution Lifecycle

#### For New Rails Applications

Create a new Rails application using the git-template:

```bash
rails new myapp -m git-template
```

#### For Existing Rails Applications

Apply the template to an existing Rails application:

```bash
cd myapp
git-template apply
```

#### Template Execution Commands

```bash
# Apply template to current directory
git-template apply

# Apply template to specific path
git-template apply /path/to/rails/app

# Show available templates
git-template list

# Show gem version
git-template version

# Show path to bundled template
git-template path

# Show help
git-template help
```

## Template Architecture

### Dual Lifecycle System

The git-template system operates with two complementary lifecycles:

#### Template Implementation Lifecycle
The development and refinement process for creating templates:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Clone Source   │───▶│  Analyze Status │───▶│  Iterate & Test │
│   Application   │    │   & Structure   │    │    Template     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                                              │
         │              ┌─────────────────┐    ┌─────────────────┐
         └──────────────│  Push Changes   │◀───│ Update Template │
                        │   to Remote     │    │ Configuration   │
                        └─────────────────┘    └─────────────────┘
```

#### Template Execution Lifecycle
The structured application of templates with specialized phases:

**Specialized Phases** (evolved from cleanup-based approach):
1. **Platform Setup** - Ruby version, Rails configuration, database setup
2. **Infrastructure Setup** - Gems, Redis, Solid Stack, deployment configuration  
3. **Frontend Setup** - Vite, Tailwind CSS, Inertia.js, Juris.js
4. **Testing Setup** - RSpec, Cucumber, testing frameworks
5. **Security Setup** - Authorization, security gems
6. **Data Flow Setup** - ActiveDataFlow integration (optional)
7. **Application Features** - Models, controllers, views, routes, admin interface

### Evolution from Cleanup Phase to Specialized Phases

The template system has evolved from a cleanup-phase approach to specialized phases:

**Previous Approach:**
- Templates would apply basic structure
- Cleanup phase would handle all customizations and fixes
- Less organized, harder to maintain

**Current Specialized Phase Approach:**
- Each phase has specific responsibilities
- Content previously in cleanup phases moved to appropriate specialized phases
- Better organization, easier maintenance and iteration
- Clear separation of concerns

### Templated Directory Structure

The git-template system uses a top-level `templated/` directory to organize template development work:

```
project-root/
├── examples/rails/myapp/           # Original application
├── templated/
│   └── examples/rails/myapp/       # Templated version for development
│       └── .git_template/          # Template configuration
└── other-files...
```

**Benefits of this structure:**
- **Clean organization**: All templated versions in one place
- **No naming conflicts**: Avoids `-templated` suffix confusion
- **Easy navigation**: Clear separation between originals and templated versions
- **Scalable**: Works well with multiple applications and nested structures

**Legacy Support:**
The system maintains backward compatibility with `-templated` suffix folders while encouraging migration to the new structure.

## Configuration Options

### Template Implementation Configuration

During template development, you can configure:

- **Status Output Format**: detailed, summary, or JSON
- **Iteration Behavior**: automatic templated folder creation, detailed comparisons
- **Update Operations**: structure refresh, issue fixes, metadata updates
- **Git Integration**: commit behavior, remote handling, initialization options

### Template Execution Configuration

During template execution, you'll be prompted for:

- **Redis Usage**: Use Redis or redis-emulator
- **ActiveDataFlow**: Include ActiveDataFlow integration
- **Docker/Kamal**: Setup deployment configuration
- **Sample Models**: Generate example Product models
- **Admin Interface**: Setup admin interface

## Programmatic Usage

### Template Implementation API

```ruby
require 'git_template'

# Status analysis
status_command = GitTemplate::Commands::StatusCommand.new
result = status_command.execute('/path/to/app')

# Clone repository for template development
clone_command = GitTemplate::Commands::CloneCommand.new
result = clone_command.execute('https://github.com/user/repo.git', 'target_folder')

# Template iteration
iterate_command = GitTemplate::Commands::IterateCommand.new
result = iterate_command.execute('/path/to/app')

# Template updates
update_command = GitTemplate::Commands::UpdateCommand.new
result = update_command.execute('/path/to/app', { fix_issues: true })

# Push changes
push_command = GitTemplate::Commands::PushCommand.new
result = push_command.execute('/path/to/app', 'remote_url')
```

### Template Execution API

```ruby
require 'git_template'

# Apply template to Rails application
GitTemplate.apply_template(rails_app_generator)

# Get path to bundled template
template_path = GitTemplate.template_path
```

### Service Layer Access

```ruby
# Direct service usage
analyzer = GitTemplate::Services::FolderAnalyzer.new
analysis = analyzer.analyze_template_development_status('/path/to/app')

git_ops = GitTemplate::Services::GitOperations.new
result = git_ops.clone_repository('git_url', 'target_path')

processor = GitTemplate::Services::TemplateProcessor.new
result = processor.iterate_template('/app/path', '/templated/path')
```

## Template Development Workflow

### Recommended Workflow for Template Creation

1. **Start with an Existing Application**
   ```bash
   git-template clone https://github.com/user/reference-app.git
   cd reference-app
   ```

2. **Analyze Current Status**
   ```bash
   git-template status . --verbose
   ```

3. **Create and Iterate Template**
   ```bash
   git-template iterate . --create-templated-folder
   ```

4. **Refine Template Through Iteration**
   ```bash
   # Make changes to your application
   # Then iterate to update template
   git-template iterate . --detailed-comparison
   ```

5. **Update and Validate Template**
   ```bash
   git-template update . --all --verbose
   ```

6. **Push Template Development Work**
   ```bash
   git-template push . --commit-changes --commit-message "Template iteration complete"
   ```

### Best Practices

- **Iterative Development**: Use the iterate command frequently to keep templates in sync
- **Status Monitoring**: Regular status checks help identify issues early
- **Specialized Phases**: Organize template logic into appropriate phases rather than cleanup
- **Version Control**: Use git integration to track template development progress
- **Validation**: Always run update commands to validate template structure

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Integration Tests

Test the status command system:

```bash
# Run integration tests
bin/test-integration

# Run with debug output
bin/test-integration --debug --verbose
```

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Command Reference

### Template Implementation Commands

| Command | Description | Key Options |
|---------|-------------|-------------|
| `git-template status FOLDER` | Analyze template development status | `--format`, `--verbose`, `--debug` |
| `git-template clone GIT_URL [TARGET]` | Clone repository for template development | `--branch`, `--create-template-config` |
| `git-template iterate FOLDER` | Iterate and refine templates | `--create-templated-folder`, `--detailed-comparison` |
| `git-template update FOLDER` | Update template configuration | `--all`, `--fix-issues`, `--update-metadata` |
| `git-template push FOLDER [REMOTE]` | Push template development work | `--commit-changes`, `--initialize-if-needed` |
| `git-template to_md FOLDER` | Convert template.rb to markdown documentation | `--output-file`, `--verbose` |

### Template Execution Commands

| Command | Description | Key Options |
|---------|-------------|-------------|
| `git-template apply [PATH]` | Apply template to Rails application | `--rails-new` |
| `git-template list` | Show available templates | - |
| `git-template version` | Show gem version | - |
| `git-template path` | Show bundled template path | - |

### Global Options

All commands support:
- `--debug`: Show debug information and stack traces
- `--verbose`: Show detailed output during execution
- `--help`: Show command-specific help information

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/username/git-template.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
