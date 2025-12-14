# Rails 8 + Juris.js Application Template

A comprehensive, modular Rails 8 application template featuring Juris.js frontend framework, ActiveDataFlow integration, and best practices for modern Rails development.

## Features

### Core Stack
- **Rails 8.1+** - Latest Rails with modern features
- **Ruby 3.3.6** - Latest stable Ruby version
- **Juris.js** - Lightweight JavaScript framework for reactive UIs
- **Inertia.js** - Seamless Rails-JavaScript integration
- **TailwindCSS** - Utility-first CSS framework
- **Vite** - Fast frontend build tool

### Infrastructure
- **SQLite3** - Database (easily switchable to PostgreSQL/MySQL)
- **Solid Cache/Queue/Cable** - Database-backed Rails infrastructure
- **Redis/Redis-emulator** - Caching and background jobs
- **Puma** - High-performance web server
- **Thruster** - HTTP asset caching and compression

### Testing
- **RSpec** - Behavior-driven development framework
- **Cucumber** - BDD testing with Gherkin syntax
- **FactoryBot** - Test data generation
- **Shoulda Matchers** - One-liner Rails tests

### Security & Quality
- **Pundit** - Authorization framework (Rails best practice)
- **Brakeman** - Security vulnerability scanner
- **Bundler Audit** - Gem vulnerability checker
- **RuboCop** - Ruby code style checker

### Data Flow
- **ActiveDataFlow** - Data transformation and ETL pipelines
- Sample Product → ProductExport flow with transformations

### Deployment
- **Docker** - Containerization
- **Kamal** - Deploy anywhere as Docker containers

### Admin Interface
- Infrastructure monitoring tab
- User management tab
- Financial overview tab

## Quick Start

### Create a New Application

```bash
rails new myapp -m https://path/to/template.rb
```

Or apply to an existing application:

```bash
cd myapp
bin/rails app:template LOCATION=https://path/to/template.rb
```

### Local Template Usage

```bash
git clone <this-repo>
cd <your-project-directory>
rails new myapp -m /path/to/rails8-juris-template/template.rb
```

## Template Structure

The template is organized into modular phases:

### Phase 1: Platform Setup
- Ruby version configuration (3.3.6)
- Rails application configuration
- Database setup

### Phase 2: Infrastructure
- Core gems installation
- Redis/cache configuration
- Solid stack setup (Cache, Queue, Cable)
- Docker and Kamal deployment configuration

### Phase 3: Frontend
- Vite configuration
- TailwindCSS setup
- Inertia.js integration
- Juris.js framework installation

### Phase 4: Testing
- RSpec configuration
- Cucumber setup
- Test helpers and support files

### Phase 5: Security
- Pundit authorization
- Security scanning tools
- Code quality tools

### Phase 6: Data Flow
- ActiveDataFlow integration
- Sample data flow configuration

### Phase 7: Application Features
- Sample models (Product, ProductExport)
- Controllers with Inertia.js
- Juris.js pages and components
- Admin interface

## Configuration Options

During template application, you'll be asked:

1. **Use Redis?** - Choose between Redis or redis-emulator
2. **Include ActiveDataFlow?** - Add data transformation capabilities
3. **Setup Docker/Kamal?** - Configure deployment tools
4. **Generate sample models?** - Create Product/ProductExport examples
5. **Setup admin interface?** - Add admin dashboard with tabs

## Modular Usage

You can apply individual modules to existing applications:

```bash
# Apply only frontend modules
bin/rails app:template LOCATION=/path/to/modules/03_frontend/vite.rb
bin/rails app:template LOCATION=/path/to/modules/03_frontend/juris.rb

# Apply only testing modules
bin/rails app:template LOCATION=/path/to/modules/04_testing/rspec.rb
```

## Development

### Start Development Server

```bash
bin/dev
```

This starts:
- Rails server on port 3000
- Vite dev server for hot reloading
- TailwindCSS watcher

### Run Tests

```bash
# RSpec
bundle exec rspec

# Cucumber
bundle exec cucumber

# All tests
bundle exec rake
```

### Security Checks

```bash
# Run all security checks
bundle exec rake security:all

# Individual checks
bundle exec brakeman
bundle exec bundler-audit check --update
```

### Code Quality

```bash
bundle exec rubocop
```

## Juris.js Framework

Juris.js is a minimal JavaScript framework included in this template that provides:

- **Template Literals** - HTML-in-JS using tagged template literals
- **State Management** - Simple `useState` hook
- **Component System** - Functional components
- **Utility Functions** - Common helpers

### Example Component

```javascript
import { html } from '@/lib/juris'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'

export default function MyPage({ data }) {
  return html`
    <div class="container mx-auto px-4 py-8">
      ${Card({
        children: html`
          ${CardHeader({
            children: CardTitle({ children: 'Hello World' })
          })}
          ${CardContent({
            children: html`<p>Content goes here</p>`
          })}
        `
      })}
    </div>
  `
}
```

## UI Components

Pre-built UI components included:

- **Table** - Data tables with header, body, rows, cells
- **Button** - Multiple variants (default, secondary, outline, ghost, link, destructive)
- **Badge** - Status badges with color variants
- **Card** - Container with header, title, content, footer

## ActiveDataFlow Example

Sample ProductSyncFlow demonstrates:

1. **Source** - Read active products from database
2. **Transform** - Convert price to cents, generate slugs
3. **Sink** - Write to ProductExport table

Trigger the flow:

```bash
curl -X POST http://localhost:3000/active_data_flow/data_flows/heartbeat
```

## Admin Interface

Access at `/admin` with three tabs:

- **Infrastructure** - System info, database, cache status
- **Users** - User management (ready for authentication integration)
- **Financial** - Revenue, expenses, profit tracking

## Deployment

### Docker

Build and run:

```bash
docker build -t myapp .
docker run -p 3000:3000 myapp
```

### Kamal

Configure `.kamal/deploy.yml` and deploy:

```bash
kamal setup
kamal deploy
```

## Customization

### Change Database

Update `config/database.yml` and Gemfile:

```ruby
# For PostgreSQL
gem 'pg'

# For MySQL
gem 'mysql2'
```

### Add Authentication

The template is ready for authentication. Add Devise or your preferred solution:

```bash
bundle add devise
rails generate devise:install
rails generate devise User
```

Update admin controllers to use authentication.

### Customize UI Components

All UI components are in `app/frontend/components/ui/` and can be modified to match your design system.

## File Structure

```
myapp/
├── app/
│   ├── controllers/
│   │   ├── admin/              # Admin controllers
│   │   ├── home_controller.rb
│   │   └── products_controller.rb
│   ├── frontend/
│   │   ├── components/
│   │   │   └── ui/             # UI components
│   │   ├── entrypoints/
│   │   │   ├── application.js
│   │   │   └── application.css
│   │   ├── layouts/
│   │   │   └── MainLayout.js
│   │   ├── lib/
│   │   │   ├── juris.js        # Framework
│   │   │   └── utils.js
│   │   └── pages/              # Inertia pages
│   ├── flows/                  # ActiveDataFlow flows
│   ├── models/
│   └── views/
├── config/
├── db/
├── spec/                       # RSpec tests
├── features/                   # Cucumber features
└── lib/tasks/                  # Rake tasks
```

## Contributing

This template is designed to be customized for your needs. Feel free to:

- Add/remove modules
- Customize UI components
- Add your own generators
- Share improvements

## License

This template is available as open source under the terms of the MIT License.

## Credits

Built with:
- Ruby on Rails
- Juris.js (custom framework)
- Inertia.js
- TailwindCSS
- Vite
- And many other amazing open source projects

## Support

For issues or questions:
1. Check the documentation
2. Review the module code
3. Open an issue on GitHub

---

**Happy coding with Rails 8 + Juris.js! 🚀**
