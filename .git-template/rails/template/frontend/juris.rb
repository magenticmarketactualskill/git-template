# Setup Juris.js framework
say "Setting up Juris.js framework...", :green

# Copy Juris.js library files
copy_file "files/frontend/lib/juris.js", "app/frontend/lib/juris.js"
copy_file "files/frontend/lib/utils.js", "app/frontend/lib/utils.js"

# Copy UI components
copy_file "files/frontend/components/ui/table.js", "app/frontend/components/ui/table.js"
copy_file "files/frontend/components/ui/button.js", "app/frontend/components/ui/button.js"
copy_file "files/frontend/components/ui/badge.js", "app/frontend/components/ui/badge.js"
copy_file "files/frontend/components/ui/card.js", "app/frontend/components/ui/card.js"

# Copy layout
copy_file "files/frontend/layouts/MainLayout.js", "app/frontend/layouts/MainLayout.js"

# Create main application.js entry point
file "app/frontend/entrypoints/application.js", <<~JS
  // Import styles
  import './application.css'
  
  // Import Inertia
  import { createInertiaApp } from '@inertiajs/core'
  import { render } from '@/lib/juris'
  
  // Import pages
  const pages = import.meta.glob('../pages/**/*.js')
  
  // Create Inertia app
  createInertiaApp({
    resolve: async (name) => {
      const pageModule = await pages[\`../pages/\${name}.js\`]()
      return pageModule.default || pageModule
    },
    setup({ el, App, props }) {
      render(App(props), el)
    },
    progress: {
      color: '#3b82f6',
    },
  })
JS

# Create Home page
run "mkdir -p app/frontend/pages/Home"
file "app/frontend/pages/Home/Index.js", <<~JS
  import { html } from '@/lib/juris'
  import MainLayout from '@/layouts/MainLayout'
  import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
  
  export default function HomeIndex() {
    return MainLayout({
      title: 'Home',
      children: html\`
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-4xl font-bold mb-8">Welcome to Rails 8 + Juris.js</h1>
          
          \${Card({
            children: html\`
              \${CardHeader({
                children: html\`
                  \${CardTitle({ children: 'Getting Started' })}
                \`
              })}
              \${CardContent({
                children: html\`
                  <p class="text-gray-600 mb-4">
                    This application is built with Rails 8 and Juris.js, a lightweight
                    JavaScript framework for building reactive user interfaces.
                  </p>
                  <ul class="list-disc list-inside space-y-2 text-gray-600">
                    <li>Rails 8 backend with modern features</li>
                    <li>Juris.js for reactive frontend</li>
                    <li>Inertia.js for seamless integration</li>
                    <li>TailwindCSS for styling</li>
                    <li>ActiveDataFlow for data transformation</li>
                  </ul>
                \`
              })}
            \`
          })}
        </div>
      \`
    })
  }
JS

say "✓ Juris.js framework configured", :green
