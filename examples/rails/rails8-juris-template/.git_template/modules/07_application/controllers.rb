# Generate controllers with Inertia.js support
say "Generating controllers...", :green

# Create HomeController
file "app/controllers/home_controller.rb", <<~RUBY
  class HomeController < ApplicationController
    def index
      render inertia: 'Home/Index'
    end
  end
RUBY

if @generate_sample_models
  # Create ProductsController
  file "app/controllers/products_controller.rb", <<~RUBY
    class ProductsController < ApplicationController
      def index
        @products = Product.order(id: :asc)
        render inertia: 'Products/Index', props: {
          products: @products.as_json(only: [:id, :sku, :name, :price, :category, :active])
        }
      end
      
      def show
        @product = Product.find(params[:id])
        render inertia: 'Products/Show', props: {
          product: @product.as_json(only: [:id, :sku, :name, :price, :category, :active])
        }
      end
    end
  RUBY
  
  # Create ProductExportsController
  file "app/controllers/product_exports_controller.rb", <<~RUBY
    class ProductExportsController < ApplicationController
      def index
        @product_exports = ProductExport.includes(:product).order(exported_at: :desc)
        render inertia: 'ProductExports/Index', props: {
          productExports: @product_exports.as_json(
            only: [:id, :name, :sku, :price_cents, :category_slug, :exported_at],
            include: {
              product: { only: [:id, :name] }
            }
          )
        }
      end
    end
  RUBY
end

say "✓ Controllers generated", :green
