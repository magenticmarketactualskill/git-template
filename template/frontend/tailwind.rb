# Setup TailwindCSS
say "Setting up TailwindCSS...", :green

# Copy tailwind.config.cjs
copy_file "files/config/tailwind.config.cjs", "tailwind.config.cjs"

# Copy postcss.config.cjs
copy_file "files/config/postcss.config.cjs", "postcss.config.cjs"

# Create application.css with Tailwind directives
file "app/frontend/entrypoints/application.css", <<~CSS
  @tailwind base;
  @tailwind components;
  @tailwind utilities;
  
  /* Custom styles */
  @layer components {
    .btn {
      @apply px-4 py-2 rounded font-semibold transition-colors;
    }
    
    .btn-primary {
      @apply bg-blue-600 text-white hover:bg-blue-700;
    }
    
    .btn-secondary {
      @apply bg-gray-600 text-white hover:bg-gray-700;
    }
    
    .card {
      @apply bg-white rounded-lg shadow-md p-6;
    }
    
    .table-container {
      @apply overflow-x-auto rounded-lg border border-gray-200;
    }
  }
CSS

say "✓ TailwindCSS configured", :green
