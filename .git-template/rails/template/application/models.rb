# Generate sample Product models
say "Generating Product models...", :green

# Generate Product model
generate :model, "Product", 
  "name:string", 
  "sku:string", 
  "price:decimal{10,2}", 
  "category:string", 
  "active:boolean"

# Generate ProductExport model
generate :model, "ProductExport",
  "product:references",
  "name:string",
  "sku:string", 
  "price_cents:integer",
  "category_slug:string",
  "exported_at:datetime"

# Create ProductSyncFlow if ActiveDataFlow is enabled
if @use_active_data_flow
  file "app/flows/product_sync_flow.rb", <<~RUBY
    # ProductSyncFlow demonstrates data transformation using ActiveDataFlow
    class ProductSyncFlow < ActiveDataFlow::Flow
      # Source: Read from Product table
      source :active_record do |config|
        config.model = Product
        config.scope = -> { where(active: true) }
      end
      
      # Transform: Convert and format data
      transform do |record|
        {
          product_id: record.id,
          name: record.name,
          sku: record.sku,
          price_cents: (record.price * 100).to_i,
          category_slug: record.category.parameterize,
          exported_at: Time.current
        }
      end
      
      # Sink: Write to ProductExport table
      sink :active_record do |config|
        config.model = ProductExport
        config.unique_by = :product_id
      end
    end
  RUBY
end

# Create seed data
file "db/seeds.rb", <<~RUBY
  # Clear existing data
  ProductExport.destroy_all
  Product.destroy_all
  
  # Create sample products
  categories = ['Electronics', 'Books', 'Clothing', 'Home & Garden', 'Sports']
  
  15.times do |i|
    Product.create!(
      name: Faker::Commerce.product_name,
      sku: "SKU-\#{(1000 + i).to_s.rjust(4, '0')}",
      price: Faker::Commerce.price(range: 10.0..500.0),
      category: categories.sample,
      active: i < 12 # First 12 are active, last 3 are inactive
    )
  end
  
  puts "Created \#{Product.count} products (\#{Product.where(active: true).count} active)"
RUBY

say "✓ Product models generated", :green
