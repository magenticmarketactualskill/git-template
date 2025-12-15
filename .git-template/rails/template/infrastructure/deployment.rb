# Setup Docker and Kamal deployment
say "Setting up Docker and Kamal deployment...", :green

# Add Kamal gem
gem "kamal", require: false, comment: "Deploy this application anywhere as a Docker container"

# Copy Dockerfile
copy_file "files/docker/Dockerfile", "Dockerfile"

# Copy .dockerignore
copy_file "files/docker/.dockerignore", ".dockerignore"

# Create .kamal directory
run "mkdir -p .kamal"

# Create basic deploy.yml for Kamal
file ".kamal/deploy.yml", <<~YAML
  # Kamal deployment configuration
  # See https://kamal-deploy.org for more information
  
  service: <%= app_name %>
  image: <%= app_name %>
  
  servers:
    web:
      - 192.168.0.1
  
  registry:
    username: your-registry-username
    password:
      - KAMAL_REGISTRY_PASSWORD
  
  env:
    secret:
      - RAILS_MASTER_KEY
  
  builder:
    arch: amd64
  
  accessories:
    db:
      image: mysql:8.0
      host: 192.168.0.1
      port: 3306
      env:
        secret:
          - MYSQL_ROOT_PASSWORD
      directories:
        - data:/var/lib/mysql
YAML

# Create Procfile.dev for development
file "Procfile.dev", <<~PROCFILE
  web: bin/rails server -p 3000
  css: bin/rails tailwindcss:watch
  js: npm run dev
PROCFILE

say "✓ Docker and Kamal deployment configured", :green
say "  Remember to update .kamal/deploy.yml with your server details", :yellow
