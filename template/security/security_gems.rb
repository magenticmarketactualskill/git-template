# Security gems are already added in gems.rb (brakeman, bundler-audit, rubocop)
say "Security gems already configured (brakeman, bundler-audit, rubocop)", :green

# Create a rake task for security checks
rakefile "security.rake", <<~RAKE
  namespace :security do
    desc "Run all security checks"
    task all: [:brakeman, :bundler_audit]
    
    desc "Run Brakeman security scanner"
    task :brakeman do
      sh "bundle exec brakeman -q -z"
    end
    
    desc "Run bundler-audit to check for vulnerable gems"
    task :bundler_audit do
      sh "bundle exec bundler-audit check --update"
    end
  end
RAKE

say "✓ Security rake tasks created", :green
say "  Run 'rake security:all' to perform security checks", :yellow
