# Rails8-Juris Modular Template Design

## Template Architecture

The template will be organized into modular parts that can be applied sequentially, following the principle of **platform first, application last**.

### Module Organization

```
rails8-juris-template/
├── template.rb                    # Main template entry point
├── modules/
│   ├── 01_platform/
│   │   ├── ruby_version.rb        # Set Ruby version (3.3.6)
│   │   ├── rails_config.rb        # Core Rails configuration
│   │   └── database.rb            # Database setup (SQLite3)
│   ├── 02_infrastructure/
│   │   ├── gems.rb                # Core gems and dependencies
│   │   ├── redis.rb               # Redis/redis-emulator setup
│   │   ├── solid_stack.rb         # Solid Cache/Queue/Cable
│   │   └── deployment.rb          # Kamal, Docker, Thruster
│   ├── 03_frontend/
│   │   ├── vite.rb                # Vite configuration
│   │   ├── juris.rb               # Juris.js framework setup
│   │   ├── inertia.rb             # Inertia.js integration
│   │   └── tailwind.rb            # TailwindCSS setup
│   ├── 04_testing/
│   │   ├── rspec.rb               # RSpec setup
│   │   └── cucumber.rb            # Cucumber setup
│   ├── 05_security/
│   │   ├── authorization.rb       # Authorization (Pundit/CanCanCan)
│   │   └── security_gems.rb       # Brakeman, bundler-audit
│   ├── 06_data_flow/
│   │   └── active_data_flow.rb    # ActiveDataFlow integration
│   └── 07_application/
│       ├── models.rb              # Generate models (Product, ProductExport)
│       ├── controllers.rb         # Generate controllers
│       ├── views.rb               # Setup Juris.js pages/components
│       ├── routes.rb              # Configure routes
│       └── admin.rb               # Admin page with infrastructure/users/financial tabs
├── files/
│   ├── frontend/
│   │   ├── lib/
│   │   │   ├── juris.js           # Custom Juris.js framework
│   │   │   └── utils.js           # Utility functions
│   │   ├── components/
│   │   │   └── ui/                # UI components (table, button, badge, card)
│   │   ├── layouts/
│   │   │   └── MainLayout.js      # Main layout
│   │   └── pages/                 # Page templates
│   ├── config/
│   │   ├── vite.config.ts
│   │   ├── tailwind.config.cjs
│   │   └── postcss.config.cjs
│   └── docker/
│       ├── Dockerfile
│       └── .dockerignore
└── README.md                       # Template usage documentation
```

## Module Execution Order

### Phase 1: Platform Setup (01_platform)
1. **ruby_version.rb** - Set .ruby-version to 3.3.6
2. **rails_config.rb** - Configure application.rb settings
3. **database.rb** - Setup database.yml for SQLite3

### Phase 2: Infrastructure (02_infrastructure)
1. **gems.rb** - Add core gems (Rails 8.1+, Propshaft, Puma, etc.)
2. **redis.rb** - Setup Redis or redis-emulator
3. **solid_stack.rb** - Configure Solid Cache, Queue, Cable
4. **deployment.rb** - Setup Kamal, Docker, Thruster

### Phase 3: Frontend (03_frontend)
1. **vite.rb** - Install and configure Vite
2. **tailwind.rb** - Setup TailwindCSS
3. **inertia.rb** - Configure Inertia.js
4. **juris.rb** - Setup Juris.js framework and structure

### Phase 4: Testing (04_testing)
1. **rspec.rb** - Install and configure RSpec
2. **cucumber.rb** - Install and configure Cucumber

### Phase 5: Security (05_security)
1. **authorization.rb** - Setup authorization (Pundit recommended)
2. **security_gems.rb** - Add Brakeman, bundler-audit, rubocop

### Phase 6: Data Flow (06_data_flow)
1. **active_data_flow.rb** - Setup ActiveDataFlow gems and configuration

### Phase 7: Application Features (07_application)
1. **models.rb** - Generate Product and ProductExport models
2. **controllers.rb** - Generate controllers with Inertia.js support
3. **views.rb** - Create Juris.js pages and components
4. **routes.rb** - Configure application routes
5. **admin.rb** - Generate admin interface with tabs

## Key Features

### Modular Design
- Each module is self-contained and can be skipped if needed
- Modules can be applied independently to existing apps
- Clear separation of concerns

### User Interaction
- Ask user for configuration choices (e.g., use Redis or redis-emulator?)
- Confirm before running destructive operations
- Provide progress feedback

### File Templates
- Pre-built Juris.js framework files
- UI component library (table, button, badge, card)
- Layout and page templates
- Configuration files (Vite, Tailwind, PostCSS)

### Best Practices
- Ruby 3.3.6 (from knowledge base)
- RSpec and Cucumber testing (from knowledge base)
- Rails best practice authorization (from knowledge base)
- Admin page with infrastructure/users/financial tabs (from knowledge base)
- UML diagrams for models and flows
- Proper documentation

## Template Entry Point (template.rb)

The main template.rb will:
1. Display welcome message and template info
2. Ask user for configuration preferences
3. Apply modules in order
4. Run post-installation tasks (bundle, migrations, etc.)
5. Display completion message with next steps

## Configuration Options

Users will be asked:
- Use Redis or redis-emulator?
- Include ActiveDataFlow? (default: yes)
- Setup Docker/Kamal deployment? (default: yes)
- Generate sample Product models? (default: yes)
- Setup admin interface? (default: yes)
