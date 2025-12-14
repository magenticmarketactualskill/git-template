# Create Juris.js pages and components
say "Creating Juris.js pages...", :green

if @generate_sample_models
  # Create Products/Index page
  run "mkdir -p app/frontend/pages/Products"
  file "app/frontend/pages/Products/Index.js", <<~JS
    import { html } from '@/lib/juris'
    import MainLayout from '@/layouts/MainLayout'
    import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table'
    import { Badge } from '@/components/ui/badge'
    import { formatCurrency } from '@/lib/utils'
    
    export default function ProductsIndex({ products = [] }) {
      return MainLayout({
        title: 'Products',
        children: html\`
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-3xl font-bold mb-6">Products</h1>
            
            <div class="table-container">
              \${Table({
                children: html\`
                  \${TableHeader({
                    children: html\`
                      \${TableRow({
                        children: html\`
                          \${TableHead({ children: 'SKU' })}
                          \${TableHead({ children: 'Name' })}
                          \${TableHead({ children: 'Price' })}
                          \${TableHead({ children: 'Category' })}
                          \${TableHead({ children: 'Status' })}
                        \`
                      })}
                    \`
                  })}
                  \${TableBody({
                    children: products.map(product => 
                      TableRow({
                        children: html\`
                          \${TableCell({ children: product.sku })}
                          \${TableCell({ children: product.name })}
                          \${TableCell({ children: formatCurrency(product.price) })}
                          \${TableCell({ children: product.category })}
                          \${TableCell({ 
                            children: Badge({ 
                              variant: product.active ? 'success' : 'secondary',
                              children: product.active ? 'Active' : 'Inactive'
                            })
                          })}
                        \`
                      })
                    ).join('')
                  })}
                \`
              })}
            </div>
          </div>
        \`
      })
    }
  JS
  
  # Create Products/Show page
  file "app/frontend/pages/Products/Show.js", <<~JS
    import { html } from '@/lib/juris'
    import MainLayout from '@/layouts/MainLayout'
    import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
    import { Badge } from '@/components/ui/badge'
    import { formatCurrency } from '@/lib/utils'
    
    export default function ProductsShow({ product }) {
      return MainLayout({
        title: \`Product: \${product.name}\`,
        children: html\`
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-3xl font-bold mb-6">\${product.name}</h1>
            
            \${Card({
              children: html\`
                \${CardHeader({
                  children: html\`
                    \${CardTitle({ children: 'Product Details' })}
                  \`
                })}
                \${CardContent({
                  children: html\`
                    <dl class="space-y-4">
                      <div>
                        <dt class="font-semibold text-gray-700">SKU</dt>
                        <dd class="text-gray-600">\${product.sku}</dd>
                      </div>
                      <div>
                        <dt class="font-semibold text-gray-700">Price</dt>
                        <dd class="text-gray-600">\${formatCurrency(product.price)}</dd>
                      </div>
                      <div>
                        <dt class="font-semibold text-gray-700">Category</dt>
                        <dd class="text-gray-600">\${product.category}</dd>
                      </div>
                      <div>
                        <dt class="font-semibold text-gray-700">Status</dt>
                        <dd>\${Badge({ 
                          variant: product.active ? 'success' : 'secondary',
                          children: product.active ? 'Active' : 'Inactive'
                        })}</dd>
                      </div>
                    </dl>
                  \`
                })}
              \`
            })}
          </div>
        \`
      })
    }
  JS
  
  # Create ProductExports/Index page
  run "mkdir -p app/frontend/pages/ProductExports"
  file "app/frontend/pages/ProductExports/Index.js", <<~JS
    import { html } from '@/lib/juris'
    import MainLayout from '@/layouts/MainLayout'
    import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table'
    import { formatCurrency, formatDate } from '@/lib/utils'
    
    export default function ProductExportsIndex({ productExports = [] }) {
      return MainLayout({
        title: 'Product Exports',
        children: html\`
          <div class="container mx-auto px-4 py-8">
            <h1 class="text-3xl font-bold mb-6">Product Exports</h1>
            
            <div class="table-container">
              \${Table({
                children: html\`
                  \${TableHeader({
                    children: html\`
                      \${TableRow({
                        children: html\`
                          \${TableHead({ children: 'SKU' })}
                          \${TableHead({ children: 'Name' })}
                          \${TableHead({ children: 'Price (cents)' })}
                          \${TableHead({ children: 'Category Slug' })}
                          \${TableHead({ children: 'Exported At' })}
                        \`
                      })}
                    \`
                  })}
                  \${TableBody({
                    children: productExports.map(exp => 
                      TableRow({
                        children: html\`
                          \${TableCell({ children: exp.sku })}
                          \${TableCell({ children: exp.name })}
                          \${TableCell({ children: exp.price_cents })}
                          \${TableCell({ children: exp.category_slug })}
                          \${TableCell({ children: formatDate(exp.exported_at) })}
                        \`
                      })
                    ).join('')
                  })}
                \`
              })}
            </div>
          </div>
        \`
      })
    }
  JS
end

say "✓ Juris.js pages created", :green
