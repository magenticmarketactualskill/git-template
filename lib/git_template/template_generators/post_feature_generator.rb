module GitTemplate
  module TemplateGenerators
    module PostFeatureGenerator
      def self.execute
        say "#~ 100_PHASE_Feature_Post_Model"
        say "Creating Post model..."
        
        generate :model, 'Post', 'title:string', 'content:text', 'published:boolean'
        
        say "#~ 100_PHASE_Feature_Post_Model_Migrate"
        say "Running database migrations..."
        
        rails_command 'db:migrate'
        
        say "#~ 100_PHASE_Feature_Post_Model_Seed"
        say "Adding sample data..."
        
        append_to_file 'db/seeds.rb', <<~RUBY

# Sample data for Rails 8 Simple
Post.create!([
  {
    title: "Welcome to Rails 8",
    content: "This is your first post in the Rails 8 Simple application.",
    published: true
  },
  {
    title: "Getting Started",
    content: "Start building your application by customizing this template.",
    published: true
  }
])
RUBY
        
        rails_command 'db:seed'
      end
    end
  end
end