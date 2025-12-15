# Create Admin interface with infrastructure, users, and financial tabs
say "Creating Admin interface...", :green

# Create Admin namespace
run "mkdir -p app/controllers/admin"

# Create Admin::DashboardController
file "app/controllers/admin/dashboard_controller.rb", <<~RUBY
  module Admin
    class DashboardController < ApplicationController
      # before_action :authorize_admin! # Uncomment when authentication is set up
      
      def index
        render inertia: 'Admin/Dashboard/Index', props: {
          tab: params[:tab] || 'infrastructure'
        }
      end
      
      private
      
      def authorize_admin!
        # Add authorization logic here
        # Example: authorize :admin, :dashboard?
      end
    end
  end
RUBY

# Create Admin::InfrastructureController
file "app/controllers/admin/infrastructure_controller.rb", <<~RUBY
  module Admin
    class InfrastructureController < ApplicationController
      # before_action :authorize_admin!
      
      def index
        render inertia: 'Admin/Infrastructure/Index', props: {
          system_info: system_information,
          database_info: database_information,
          cache_info: cache_information
        }
      end
      
      private
      
      def system_information
        {
          ruby_version: RUBY_VERSION,
          rails_version: Rails.version,
          environment: Rails.env
        }
      end
      
      def database_information
        {
          adapter: ActiveRecord::Base.connection.adapter_name,
          database: ActiveRecord::Base.connection.current_database
        }
      end
      
      def cache_information
        {
          store: Rails.cache.class.name
        }
      end
    end
  end
RUBY

# Create Admin::UsersController
file "app/controllers/admin/users_controller.rb", <<~RUBY
  module Admin
    class UsersController < ApplicationController
      # before_action :authorize_admin!
      
      def index
        # @users = User.all # Uncomment when User model exists
        render inertia: 'Admin/Users/Index', props: {
          users: [] # Replace with actual users
        }
      end
    end
  end
RUBY

# Create Admin::FinancialController
file "app/controllers/admin/financial_controller.rb", <<~RUBY
  module Admin
    class FinancialController < ApplicationController
      # before_action :authorize_admin!
      
      def index
        render inertia: 'Admin/Financial/Index', props: {
          revenue: financial_summary[:revenue],
          expenses: financial_summary[:expenses],
          profit: financial_summary[:profit]
        }
      end
      
      private
      
      def financial_summary
        # Add actual financial logic here
        {
          revenue: 0,
          expenses: 0,
          profit: 0
        }
      end
    end
  end
RUBY

# Create Admin Dashboard page
run "mkdir -p app/frontend/pages/Admin/Dashboard"
file "app/frontend/pages/Admin/Dashboard/Index.js", <<~JS
  import { html } from '@/lib/juris'
  import MainLayout from '@/layouts/MainLayout'
  import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
  
  export default function AdminDashboardIndex({ tab = 'infrastructure' }) {
    const tabs = [
      { id: 'infrastructure', label: 'Infrastructure' },
      { id: 'users', label: 'Users' },
      { id: 'financial', label: 'Financial' }
    ]
    
    return MainLayout({
      title: 'Admin Dashboard',
      children: html\`
        <div class="container mx-auto px-4 py-8">
          <h1 class="text-3xl font-bold mb-6">Admin Dashboard</h1>
          
          <div class="mb-6">
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-8">
                \${tabs.map(t => html\`
                  <a
                    href="/admin?tab=\${t.id}"
                    class="
                      \${tab === t.id 
                        ? 'border-blue-500 text-blue-600' 
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
                      whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm
                    "
                  >
                    \${t.label}
                  </a>
                \`).join('')}
              </nav>
            </div>
          </div>
          
          <div id="tab-content">
            \${tab === 'infrastructure' ? html\`
              \${Card({
                children: html\`
                  \${CardHeader({
                    children: CardTitle({ children: 'Infrastructure Overview' })
                  })}
                  \${CardContent({
                    children: html\`
                      <p class="text-gray-600">Infrastructure monitoring and management.</p>
                      <p class="text-sm text-gray-500 mt-2">Visit /admin/infrastructure for details.</p>
                    \`
                  })}
                \`
              })}
            \` : ''}
            
            \${tab === 'users' ? html\`
              \${Card({
                children: html\`
                  \${CardHeader({
                    children: CardTitle({ children: 'User Management' })
                  })}
                  \${CardContent({
                    children: html\`
                      <p class="text-gray-600">User accounts and permissions.</p>
                      <p class="text-sm text-gray-500 mt-2">Visit /admin/users for details.</p>
                    \`
                  })}
                \`
              })}
            \` : ''}
            
            \${tab === 'financial' ? html\`
              \${Card({
                children: html\`
                  \${CardHeader({
                    children: CardTitle({ children: 'Financial Overview' })
                  })}
                  \${CardContent({
                    children: html\`
                      <p class="text-gray-600">Revenue, expenses, and financial reports.</p>
                      <p class="text-sm text-gray-500 mt-2">Visit /admin/financial for details.</p>
                    \`
                  })}
                \`
              })}
            \` : ''}
          </div>
        </div>
      \`
    })
  }
JS

# Add admin routes
route "namespace :admin do"
route "  get '/', to: 'dashboard#index'"
route "  resources :infrastructure, only: [:index]"
route "  resources :users, only: [:index]"
route "  resources :financial, only: [:index]"
route "end"

say "✓ Admin interface created with infrastructure, users, and financial tabs", :green
