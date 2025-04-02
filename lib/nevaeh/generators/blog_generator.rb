module Nevaeh
  module Generators
    class BlogGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      def generate
        create_blog_model
        create_article_model
        create_brand_methods
        create_blog_methods
        add_action_text_to_articles
        create_blog_center
      end

      private
      
      def create_blog_model
        #generate "model", "Blog title:string handle:string url:string"
        generate "nevaeh:scaffold_rich_text Blog --fields title:string handle:text url:string published:boolean"
      end

      def create_article_model
        #generate "model", "Article title:string blog:references comments_enabled:boolean moderated:boolean published_at:datetime"
        #generate "action_text:install"
        #generate "migration AddContentToArticles content:text"
        
        generate "nevaeh:scaffold_rich_text Article --fields title:string blog:references user:references comments_enabled:boolean moderated:boolean published_at:datetime published:boolean"

        article_model_path = "app/models/article.rb" # Define the path

        if File.exist?(article_model_path)
          insert_into_file article_model_path, "\n  include Schedulable", after: "class Article < ApplicationRecord"
        else
          create_file article_model_path, <<~RUBY
            class Article < ApplicationRecord
              include Schedulable
            end
          RUBY
        end
      end
      
      def create_brand_methods
        inject_into_class "app/models/blog.rb", "Blog" do
          <<-RUBY
            # Brand colors logic
            def brand_colors
              {
                primary: {
                  background: brand.colors.primary[0].background,
                  foreground: brand.colors.primary[0].foreground
                },
                secondary: {
                  background: brand.colors.secondary[0].background,
                  foreground: brand.colors.secondary[0].foreground
                }
              }
            end

            def brand_logo
              brand.logo
            end

            def brand_slogan
              brand.slogan
            end

            def brand_description
              brand.short_description
            end
          RUBY
        end
      end

      def create_blog_methods
        inject_into_class "app/models/blog.rb", "Blog" do
          <<-RUBY
            has_many :articles
        
            def all_tags
              articles.flat_map(&:tags).uniq
            end

            def articles_count
              articles.count
            end

            def comments_enabled?
              # Returns true if any article in the blog has comments enabled
              articles.any?(&:comments_enabled)
            end

            def moderated?
              # Returns true if any article in the blog is moderated
              articles.any?(&:moderated?)
            end

            def next_article(article)
              articles.where("id > ?", article.id).order(:id).first
            end

            def previous_article(article)
              articles.where("id < ?", article.id).order(id: :desc).first
            end

            def as_json(options = {})
              super(options.merge({
                include: { articles: { only: [:id, :title] } }
              }))
            end
          RUBY
        end
      end

      def add_action_text_to_articles
        inject_into_class "app/models/article.rb", "Article" do
          "  has_rich_text :content\n"
        end
      end
      
      def create_blog_center
        schedule_of_tasks
      end
      
      def schedule_of_tasks
        create_concern
        create_job
        create_service
        create_articles_controller
        create_comments
        create_replies
      end
      
      def create_comments
        generate "nevaeh:scaffold_rich_text Comment --fields article:references handle:text url:string published:boolean"
      end
      
      def create_replies
        generate "nevaeh:scaffold_rich_text CommentReply --fields comment:references handle:text url:string published:boolean"
        generate "nevaeh:scaffold_rich_text ReplyCommentReply --fields comment_reply:references handle:text url:string published:boolean"
      end
      
      def create_concern
        copy_file "schedulable.rb", "app/models/concerns/schedulable.rb"
      end

      def create_job
        copy_file "publish_article_job.rb", "app/jobs/publish_article_job.rb"
      end

      def create_service
        copy_file "article_scheduler_service.rb", "app/services/article_scheduler_service.rb"
      end
        
      def create_articles_controller
        copy_file "articles_controller.rb", "app/controllers/articles_controller.rb"
      end
      
      def create_routes_controller
        <<-RUBY
        class RoutesController < ApplicationController
          def index
            routes = Rails.application.routes.routes.map do |route|
              path = route.path.spec.to_s
              next if path.start_with?("/rails") # Exclude Rails engine/system routes

              {
                name: route.name,
                path: path,
                verb: extract_http_verb(route),
                controller: route.defaults[:controller],
                action: route.defaults[:action]
              }
            end.compact # Remove nil values

            # Group by controller
            grouped_routes = routes.group_by { |r| r[:controller] }

            render json: grouped_routes
          end

          private

          def extract_http_verb(route)
            verbs = route.verb.to_s.gsub(/[^A-Z|]/, '').split('|')
            verbs.size == 1 ? verbs.first : verbs
          end
        end
        
        RUBY
      end
      
    end  # Closing BlogGenerator class
  end  # Closing Generators module
end  # Closing Nevaeh module
