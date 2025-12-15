# Configure application routes
say "Configuring routes...", :green

# Set root route
route "root 'home#index'"

if @generate_sample_models
  # Add product routes
  route "resources :products, only: [:index, :show]"
  route "resources :product_exports, only: [:index]"
end

say "✓ Routes configured", :green
