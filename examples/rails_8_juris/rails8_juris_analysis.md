# Rails8-Juris Repository Analysis

## Key Dependencies from Gemfile

### Core Rails
- Rails 8.1.1+
- SQLite3 ~> 2.1
- Puma ~> 5.0 (web server)
- Propshaft (asset pipeline)

### Frontend
- importmap-rails (JavaScript with ESM import maps)
- turbo-rails (Hotwire's SPA-like page accelerator)
- stimulus-rails (Hotwire's modest JavaScript framework)
- tailwindcss-rails (Tailwind CSS)

### Data Flow
- active_data_flow gems (path references to parent repo):
  - active_data_flow-connector-source-active_record
  - active_data_flow-connector-sink-active_record
  - active_data_flow-runtime-heartbeat

### Infrastructure
- kamal (deployment)
- thruster (HTTP asset caching/compression)
- image_processing ~> 1.2 (Active Storage variants)
- redis ~> 4.0
- redis-emulator (vendor/redis-emulator)
- solid_cache, solid_queue, solid_cable (Redis alternatives)

### Development/Test
- debug (debugging)
- bundler-audit (security audits)
- brakeman (security vulnerabilities)
- rubocop-rails-omakase (Ruby styling)
- web-console (debugging)

### Submoduler
- submoduler-core-submoduler_parent (git reference)

## Application Structure

### Frontend (Juris.js)
```
app/frontend/
├── entrypoints/
│   ├── application.js          # Main Juris.js + Inertia entry point
│   └── application.css         # TailwindCSS styles
├── pages/
│   ├── Home/Index.js
│   ├── Products/
│   │   ├── Index.js
│   │   └── Show.js
│   ├── ProductExports/
│   │   └── Index.js
│   └── DataFlows/
│       └── Index.js
├── components/
│   └── ui/
│       ├── table.js
│       ├── button.js
│       ├── badge.js
│       └── card.js
├── layouts/
│   └── MainLayout.js
└── lib/
    ├── juris.js               # Custom Juris.js framework
    └── utils.js
```

### Backend Models
- Product (source table): name, sku, price, category, active
- ProductExport (destination table): product_id, name, sku, price_cents, category_slug, exported_at
- ProductSyncFlow: Data transformation flow

## Key Features
1. ActiveDataFlow integration for data transformation
2. Juris.js custom framework (template literals, custom useState)
3. Inertia.js for Rails integration
4. TailwindCSS for styling
5. Vite for frontend build
6. Docker/Kamal deployment ready


## Rails Template API Summary

### Key Template Methods

1. **gem(*args)** - Add gems to Gemfile
2. **gem_group(*names, &block)** - Group gems by environment
3. **add_source(source, options={}, &block)** - Add gem sources
4. **environment/application(data, options={}, &block)** - Add config to application.rb or environment files
5. **initializer(filename, data, &block)** - Create initializers in config/initializers
6. **file(filename, data, &block)** - Create files with directory structure
7. **lib(filename, data, &block)** - Create files in lib/
8. **vendor(filename, data, &block)** - Create files in vendor/
9. **rakefile(filename, data, &block)** - Create rake tasks in lib/tasks
10. **generate(what, *args)** - Run Rails generators
11. **run(command)** - Execute shell commands
12. **rails_command(command, options={})** - Run Rails commands (db:migrate, etc.)
13. **route(routing_code)** - Add routes to config/routes.rb
14. **inside(dir, &block)** - Execute commands in a specific directory
15. **ask(question)** - Get user input
16. **yes?(question)** / **no?(question)** - Ask yes/no questions
17. **git(:command)** - Run git commands
18. **after_bundle(&block)** - Execute code after bundle install

### Template Usage

```bash
# New application
rails new blog -m ~/template.rb
rails new blog -m http://example.com/template.rb

# Existing application
bin/rails app:template LOCATION=~/template.rb
bin/rails app:template LOCATION=http://example.com/template.rb
```

### Advanced Usage

Templates are evaluated in the context of `Rails::Generators::AppGenerator` and can use Thor's `apply` action. Can override `source_paths` for relative file operations.

### Modular Template Strategy

Templates can be split into modules by:
1. Using separate files for different concerns
2. Loading modules with `apply "path/to/module.rb"` or remote URLs
3. Organizing by: platform setup → infrastructure → application features
