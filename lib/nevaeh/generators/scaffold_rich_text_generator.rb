module Nevaeh
  module Generators
    class ScaffoldRichTextGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      class_option :fields, type: :array, default: ["title:string"], desc: "Specify fields for scaffold"

      def create_scaffold
        fields = options[:fields] + ["content:text"] # Ensure content is always included
        generate "scaffold", "#{file_name} #{fields.join(' ')}"
        inject_rich_text
        remove_text_content_column
        update_views
        create_controller
        add_routes_for_json_actions
      end

      private

      def inject_rich_text
        inject_into_class "app/models/#{file_name}.rb", file_name.classify do
          "  has_rich_text :content\n"
        end
      end

      def remove_text_content_column
        migration_file = Dir.glob("db/migrate/*_create_#{file_name.pluralize}.rb").first
        return unless migration_file

        gsub_file migration_file, /t.text :content/, "# t.text :content  # Replaced by Action Text"
      end

      def update_views
        update_form
        update_show_view
      end

      def update_form
        gsub_file "app/views/#{file_name.pluralize}/_form.html.erb",
                  /<%= form.text_area :content %>/,
                  "<%= form.rich_text_area :content %>"
      end

      def update_show_view
        gsub_file "app/views/#{file_name.pluralize}/show.html.erb",
                  /<%= @#{file_name}.content %>/,
                  "<%= @#{file_name}.content.to_s.html_safe %>"
      end

      def create_controller
        controller_file = "app/controllers/#{file_name.pluralize}_controller.rb"

        unless File.read(controller_file).include?("def create_from_json")
          inject_into_class controller_file, "#{file_name.classify}Controller" do
            <<-RUBY
            def show_as_json
              @#{file_name} = #{file_name.classify}.find(params[:id])
              render json: convert_to_json(@#{file_name}.content)
            end

            def create_from_json
              content_data = params.require(:content).permit(:text)
              @#{file_name} = #{file_name.classify}.new(content: content_data[:text])

              if @#{file_name}.save
                render json: @#{file_name}, status: :created
              else
                render json: @#{file_name}.errors, status: :unprocessable_entity
              end
            end

            private

            def convert_to_json(content)
              json_content = []

              Nokogiri::HTML(content.to_s).traverse do |node|
                case node.name
                when 'b'
                  json_content << { type: 'bold', content: node.text }
                when 'i'
                  json_content << { type: 'italic', content: node.text }
                when 'a'
                  json_content << { type: 'link', href: node['href'], content: node.text }
                when 'p'
                  json_content << { type: 'paragraph', content: node.text }
                when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
                  json_content << { type: 'header', level: node.name, content: node.text }
                end
              end

              json_content
            end
            RUBY
          end
        end
      end

      def add_routes_for_json_actions
        route = <<-ROUTE
        resources :#{file_name.pluralize} do
          member do
            get :show_as_json
            post :create_from_json
          end
        end
        ROUTE

        inject_into_file "config/routes.rb", route, before: "end"
      end
    end
  end
end






# module Nevaeh
#   module Generators
#     class ScaffoldRichTextGenerator < Rails::Generators::NamedBase
#       source_root File.expand_path("templates", __dir__)
#
#       def create_scaffold
#         generate "scaffold", "#{file_name} title:string content:text"
#         inject_into_class "app/models/#{file_name}.rb", file_name.classify do
#           "  has_rich_text :content\n"
#         end
#         remove_text_content_column
#         update_form
#         update_show_view
#         create_controller
#         add_routes_for_json_actions
#       end
#
#       private
#
#       def remove_text_content_column
#         migration_file = Dir.glob("db/migrate/*_create_#{file_name.pluralize}.rb").first
#         if migration_file
#           gsub_file migration_file, /t.text :content/, "# t.text :content  # Replaced by Action Text"
#         end
#       end
#
#       def update_form
#         gsub_file "app/views/#{file_name.pluralize}/_form.html.erb",
#                   /<%= form.text_area :content %>/,
#                   "<%= form.rich_text_area :content %>"
#       end
#
#       def update_show_view
#         gsub_file "app/views/#{file_name.pluralize}/show.html.erb",
#                   /<%= @#{file_name}.content %>/,
#                   "<%= @#{file_name}.content.to_s.html_safe %>"
#       end
#
#       def create_controller
#         controller_file = "app/controllers/#{file_name.pluralize}_controller.rb"
#
#         unless File.read(controller_file).include?("def create_from_json")
#           inject_into_class controller_file, "#{file_name.classify}Controller" do
#             <<-RUBY
#             def show_as_json
#               @#{file_name} = #{file_name.classify}.find(params[:id])
#               render json: convert_to_json(@#{file_name}.content)
#             end
#
#             def create_from_json
#               content_data = params.require(:content).permit(:text)
#               @#{file_name} = #{file_name.classify}.new(content: content_data[:text])
#
#               if @#{file_name}.save
#                 render json: @#{file_name}, status: :created
#               else
#                 render json: @#{file_name}.errors, status: :unprocessable_entity
#               end
#             end
#
#             private
#
#             def convert_to_json(content)
#               json_content = []
#
#               Nokogiri::HTML(content.to_s).traverse do |node|
#                 case node.name
#                 when 'b'
#                   json_content << { type: 'bold', content: node.text }
#                 when 'i'
#                   json_content << { type: 'italic', content: node.text }
#                 when 'a'
#                   json_content << { type: 'link', href: node['href'], content: node.text }
#                 when 'p'
#                   json_content << { type: 'paragraph', content: node.text }
#                 when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
#                   json_content << { type: 'header', level: node.name, content: node.text }
#                 end
#               end
#
#               json_content
#             end
#             RUBY
#           end
#         end
#       end
#
#       def add_routes_for_json_actions
#         route = <<-ROUTE
#         resources :#{file_name.pluralize} do
#           member do
#             get :show_as_json
#             post :create_from_json
#           end
#         end
#         ROUTE
#
#         inject_into_file "config/routes.rb", route, before: "end"
#       end
#
#       def create_parser_service
#         parser_service_content = <<-RUBY
#         class ActionTextParser
#           def self.parse(rich_text)
#             elements = []
#
#             rich_text.scan(/\[(.*?)\](.*?)\[\/\1\]/m) do |tag, content|
#               case tag
#               when /^header level="(h[1-6])"$/
#                 elements << { type: "header", level: $1, content: content.strip }
#               when "paragraph"
#                 elements << { type: "paragraph", content: content.strip }
#               when "bold"
#                 elements << { type: "bold", content: content.strip }
#               when "italic"
#                 elements << { type: "italic", content: content.strip }
#               when /^link href="(.+)"$/
#                 elements << { type: "link", content: content.strip, href: $1 }
#               when /^image src="(.+)"$/
#                 elements << { type: "image", src: $1.strip }
#               when "unordered-list"
#                 items = content.strip.split("\n").map { |line| line.gsub(/^- /, '').strip }
#                 elements << { type: "unordered_list", items: items }
#               end
#             end
#
#             elements
#           end
#         end
#         RUBY
#
#         create_action_text_parser
#       end
#
#       def create_action_text_parser
#         action_text_parser = "app/services/action_text_parser.rb"
#         template_path = "templates/action_text_parser.rb" # Replace with actual path to template
#
#         unless File.exist?(action_text_parser)
#           FileUtils.cp(template_path, action_text_parser)
#         end
#       end
#
#       def create_content_controller
#         controller_file = "app/controllers/#{file_name.pluralize}_content_controller.rb"
#
#         unless File.exist?(controller_file)
#           create_file controller_file, <<-RUBY
#           class #{file_name.classify}ContentController < ApplicationController
#             def show
#               content = ActionTextParser.parse(params[:content])
#               render json: content
#             end
#           end
#           RUBY
#         end
#       end
#     end
#   end
# end