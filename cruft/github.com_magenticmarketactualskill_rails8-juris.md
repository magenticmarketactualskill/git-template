# GitHub - magenticmarketactualskill/rails8-juris: Rails 8 + Juris.js Demo App - ActiveDataFlow Example

**URL:** https://github.com/magenticmarketactualskill/rails8-juris

---

Skip to content
Navigation Menu
Platform
Solutions
Resources
Open Source
Enterprise
Pricing
Sign in
Sign up
magenticmarketactualskill
/
rails8-juris
Public
Notifications
Fork 0
 Star 0
Code
Issues
Pull requests
2
Actions
Projects
Security
Insights
magenticmarketactualskill/rails8-juris
 main
3 Branches
0 Tags
Code
Folders and files
Name	Last commit message	Last commit date

Latest commit
laquereric
Add project specifications from parent repository
eeeb254
 · 
History
2 Commits


.antigravity
	
Initial commit: Rails 8 + Juris.js demo app
	


.github
	
Initial commit: Rails 8 + Juris.js demo app
	


.kamal
	
Initial commit: Rails 8 + Juris.js demo app
	


.kiro/specs
	
Add project specifications from parent repository
	


.vscode
	
Initial commit: Rails 8 + Juris.js demo app
	


app
	
Initial commit: Rails 8 + Juris.js demo app
	


bin
	
Initial commit: Rails 8 + Juris.js demo app
	


config
	
Initial commit: Rails 8 + Juris.js demo app
	


db
	
Initial commit: Rails 8 + Juris.js demo app
	


lib/tasks
	
Initial commit: Rails 8 + Juris.js demo app
	


public
	
Initial commit: Rails 8 + Juris.js demo app
	


script
	
Initial commit: Rails 8 + Juris.js demo app
	


storage
	
Initial commit: Rails 8 + Juris.js demo app
	


test/adhoc
	
Initial commit: Rails 8 + Juris.js demo app
	


vendor
	
Initial commit: Rails 8 + Juris.js demo app
	


.dockerignore
	
Initial commit: Rails 8 + Juris.js demo app
	


.gitattributes
	
Initial commit: Rails 8 + Juris.js demo app
	


.gitignore
	
Initial commit: Rails 8 + Juris.js demo app
	


.rubocop.yml
	
Initial commit: Rails 8 + Juris.js demo app
	


.ruby-version
	
Initial commit: Rails 8 + Juris.js demo app
	


.submoduler.ini
	
Initial commit: Rails 8 + Juris.js demo app
	


Dockerfile
	
Initial commit: Rails 8 + Juris.js demo app
	


Gemfile
	
Initial commit: Rails 8 + Juris.js demo app
	


Gemfile.lock
	
Initial commit: Rails 8 + Juris.js demo app
	


Procfile.dev
	
Initial commit: Rails 8 + Juris.js demo app
	


README.md
	
Initial commit: Rails 8 + Juris.js demo app
	


Rakefile
	
Initial commit: Rails 8 + Juris.js demo app
	


components.json
	
Initial commit: Rails 8 + Juris.js demo app
	


config.ru
	
Initial commit: Rails 8 + Juris.js demo app
	


package-lock.json
	
Initial commit: Rails 8 + Juris.js demo app
	


package.json
	
Initial commit: Rails 8 + Juris.js demo app
	


postcss.config.cjs
	
Initial commit: Rails 8 + Juris.js demo app
	


tailwind.config.cjs
	
Initial commit: Rails 8 + Juris.js demo app
	


test_redis.rb
	
Initial commit: Rails 8 + Juris.js demo app
	


tsconfig.json
	
Initial commit: Rails 8 + Juris.js demo app
	


tsconfig.node.json
	
Initial commit: Rails 8 + Juris.js demo app
	


vite.config.ts
	
Initial commit: Rails 8 + Juris.js demo app
	
Repository files navigation
README
Rails 8 + Juris.js Demo App - ActiveDataFlow Example

This is a demonstration Rails 8 application showcasing ActiveDataFlow functionality using Juris.js instead of React. The app demonstrates the same product catalog synchronization use case with data transformation as the React version, but implemented with a different frontend framework.

Overview

This demo app illustrates how to integrate ActiveDataFlow into a Rails application using Juris.js to:

Read data from a source table (products)
Transform the data (price conversion, slug generation)
Write to a destination table (product_exports)
Monitor DataFlow execution through a web interface
Key Differences from React Version
Frontend Framework
React Version: Uses React with TypeScript and JSX
Juris.js Version: Uses vanilla JavaScript with a custom component system
Similarities: Both use Inertia.js for Rails integration and TailwindCSS for styling
Component Patterns
React Components
export default function ProductsIndex({ products }: { products: Product[] }) {
    return (
        <MainLayout>
            <Table>
                {products.map((product) => (
                    <TableRow key={product.id}>
                        <TableCell>{product.name}</TableCell>
                    </TableRow>
                ))}
            </Table>
        </MainLayout>
    )
}
Juris.js Components
export default function ProductsIndex({ products = [] }) {
  return MainLayout({
    children: html`
      ${Table({
        children: products.map(product => 
          TableRow({
            children: html`${TableCell({ children: product.name })}`
          })
        ).join('')
      })}
    `
  })
}
Build System
React Version: Vite with React plugin and TypeScript
Juris.js Version: Vite with vanilla JavaScript and custom Juris.js framework
Requirements
Ruby 2.7 or higher
Rails 8.1+
SQLite3
Node.js 18+ (for frontend build)
Setup Instructions
1. Clone the Repository

If you're cloning the parent repository with submodules:

git clone --recursive https://github.com/yourusername/active_data_flow.git
cd active_data_flow/submodules/examples/rails8-juris

Or if you already have the repository:

cd active_data_flow/submodules/examples/rails8-juris
2. Install Dependencies

Install Ruby dependencies:

bundle install

Install JavaScript dependencies:

npm install
3. Setup Database

Create the database, run migrations, and load seed data:

rails db:create
rails db:migrate
rails db:seed

This will create:

15 sample products (12 active, 3 inactive)
Database tables for products and product_exports
4. Build Frontend Assets

Build the Juris.js frontend:

npm run build

For development with hot reloading:

npm run dev
5. Start the Server
rails server

The application will be available at http://localhost:3000

Application Structure
Backend (Identical to React Version)

Product: Source table containing product catalog data

Fields: name, sku, price, category, active

ProductExport: Destination table for transformed product data

Fields: product_id, name, sku, price_cents, category_slug, exported_at

ProductSyncFlow: Demonstrates data transformation

Filters active products only
Converts price to cents (multiply by 100)
Generates category slugs using parameterize
Adds export timestamp
Frontend (Juris.js Implementation)
app/frontend/
├── entrypoints/
│   ├── application.js          # Main Juris.js + Inertia entry point
│   └── application.css         # TailwindCSS styles
├── pages/
│   ├── Home/Index.js          # Home page component
│   ├── Products/
│   │   ├── Index.js           # Products listing
│   │   └── Show.js            # Product detail
│   ├── ProductExports/
│   │   └── Index.js           # Product exports listing
│   └── DataFlows/
│       └── Index.js           # DataFlow management
├── components/
│   └── ui/
│       ├── table.js           # Table components
│       ├── button.js          # Button component
│       ├── badge.js           # Badge component
│       └── card.js            # Card components
├── layouts/
│   └── MainLayout.js          # Main application layout
└── lib/
    ├── juris.js               # Custom Juris.js framework
    └── utils.js               # Utility functions

Juris.js Framework

This demo includes a minimal Juris.js-like framework implementation for demonstration purposes:

Component Definition
import { html } from '@/lib/juris'

export function Button({ children, variant = 'default', onClick }) {
  return html`
    <button class="px-4 py-2 rounded ${variant}" onclick="${onClick}">
      ${children}
    </button>
  `
}
Template Literals
import { html } from '@/lib/juris'

const template = html`
  <div class="container">
    <h1>${title}</h1>
    ${items.map(item => html`<p>${item}</p>`).join('')}
  </div>
`
State Management
import { useState } from '@/lib/juris'

const [count, setCount] = useState(0)
Usage
View Products

Visit http://localhost:3000 to see the list of products in the catalog.

View Exports

Visit http://localhost:3000/product_exports to see products that have been exported.

Trigger DataFlow

Trigger the DataFlow processing:

curl -X POST http://localhost:3000/active_data_flow/data_flows/heartbeat

Or visit the DataFlows dashboard at http://localhost:3000/active_data_flow/data_flows

Development
Frontend Development

Start the development server with hot reloading:

npm run dev

Build for production:

npm run build
Adding New Components
Create component in app/frontend/components/
Export component function
Import and use in pages or other components

Example:

// app/frontend/components/ui/alert.js
import { html } from '@/lib/juris'

export function Alert({ children, variant = 'info' }) {
  return html`
    <div class="alert alert-${variant}">
      ${children}
    </div>
  `
}
Adding New Pages
Create page component in app/frontend/pages/
Add to pages object in application.js
Create corresponding Rails controller action
Comparison with React Version
Feature	React Version	Juris.js Version
Components	JSX with TypeScript	Template literals with JavaScript
State Management	React hooks	Custom useState implementation
Build System	Vite + React plugin	Vite + custom setup
Type Safety	TypeScript	JavaScript (optional TypeScript)
Bundle Size	Larger (React runtime)	Smaller (minimal framework)
Learning Curve	React ecosystem	Simpler, vanilla JS concepts
Performance	Virtual DOM	Direct DOM manipulation
Integration with Inertia.js and Rails
Rails Controller
class ProductsController < ApplicationController