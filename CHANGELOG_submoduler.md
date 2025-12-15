# Changelog

All notable changes to the submoduler gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-15

### Added
- Initial release of unified submoduler gem
- Automatic mode detection for parent/child repositories
- Unified CLI interface with context-aware commands
- Configuration management via .submoduler.ini files
- Repository operations for initialization, validation, and submodule management
- Component integration system for delegating to parent/child gems
- Comprehensive error handling with actionable error messages
- Support for both parent mode (managing submodules) and child mode (being a submodule)

### Features
- `submoduler init` - Initialize repository with automatic or manual mode detection
- `submoduler status` - Show current repository status and mode
- `submoduler validate` - Validate repository configuration and structure
- `submoduler add` - Add new submodules (parent mode)
- `submoduler update` - Update submodules (parent mode) or sync with parent (child mode)
- `submoduler sync` - Synchronize with parent repository (child mode)
- `submoduler help` - Context-aware help system

### Technical Details
- Ruby 2.7+ compatibility
- Standard gem structure with proper metadata
- Semantic versioning
- Component delegation pattern for backward compatibility
- Git context analysis for automatic mode detection