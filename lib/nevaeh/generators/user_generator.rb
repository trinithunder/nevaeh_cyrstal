module Nevaeh
  module Generators
    class UserGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      # Override the default `generate` method, but don't pass any arguments.
      def generate
        generate_user
      end

     private

      def check_and_install_devise
        unless defined?(Devise)
          generate "devise:install"
          generate "devise", "User"
        end
      end

      def check_and_install_theme_system
        unless ActiveRecord::Base.connection.table_exists?('themes')
          generate "nevaeh:theme"
          create_theme_model
        end
      end

      def create_theme_model
        generate "model", "Theme name:string font:string color_scheme:string"
        rake "db:migrate"
      end

      def create_user_model
        generate "migration", "AddFieldsToUsers name:string role:integer theme_id:integer"
        inject_into_class "app/models/user.rb", "User", <<-RUBY
          enum role: { admin: 0, editor: 1, user: 2 }
          belongs_to :theme, optional: true
          after_initialize :set_default_role

          private
          def set_default_role
            self.role ||= :user
          end
        RUBY
        rake "db:migrate"
      end

      def create_user_controller
        create_file "app/controllers/users_controller.rb", <<-FILE
          class UsersController < ApplicationController
            before_action :set_user, only: [:show]

            def index
              @users = User.all
              respond_to do |format|
                format.html
                format.json { render json: @users }
              end
            end

            def show
              respond_to do |format|
                format.html
                format.json { render json: @user }
              end
            end

            private
            def set_user
              @user = User.find(params[:id])
            end
          end
        FILE
      end

      def create_views
        create_file "app/views/users/index.html.erb", <<-FILE
          <h1>Users</h1>
          <%= render partial: 'user_card', collection: @users, as: :user %>
        FILE

        create_file "app/views/users/show.html.erb", <<-FILE
          <h1><%= @user.name %></h1>
          <p>Role: <%= @user.role.capitalize %></p>
          <%= @user.bio&.to_html %>
        FILE
      end

      def create_partials
        create_file "app/views/users/_user_card.html.erb", <<-FILE
          <div class="user-card" style="font-family: <%= user.theme&.font %>; background-color: <%= user.theme&.color_scheme %>;">
            <h2><%= user.name %></h2>
            <p>Role: <%= user.role.capitalize %></p>
          </div>
        FILE
      end

      def add_routes
        route "resources :users, only: [:index, :show]"
      end

      def setup_action_text
        generate "action_text:install"
        rake "db:migrate"
      end

      def create_components_table
        generate "migration", "CreateComponents name:string component_type:string access_roles:text"
        rake "db:migrate"
      end

      def seed_components
        create_file "db/seeds/components.rb", <<-FILE
          Component.create!(name: 'user_profile_bio', component_type: 'user', access_roles: ['admin', 'editor', 'user'])
        FILE
      end

      def insert_action_text_component
        create_file "app/models/user_component.rb", <<-FILE
          class UserComponent < ApplicationRecord
            has_rich_text :content

            def render_html
              content.body.to_s.gsub(/<user-profile-bio user_id=\"(\d+)\"\/>/) do
                user = User.find_by(id: $1)
                user && user.allowed_component?('user_profile_bio') ? ApplicationController.render(partial: 'users/profile_bio', locals: { user: user }) : ''
              end
            end

            def render_json
              { content: render_html }.to_json
            end
          end
        FILE
      end

      def create_user_profile_bio_partial
        create_file "app/views/users/_profile_bio.html.erb", <<-FILE
          <div class="user-profile-bio">
            <h2><%= user.name %></h2>
            <p><%= user.bio %></p>
          </div>
        FILE
      end

      def add_authorization_logic
        inject_into_class "app/models/user.rb", "User", <<-RUBY
          def allowed_component?(component_name)
            component = Component.find_by(name: component_name)
            component && (component.access_roles.include?(self.role) || self.admin?)
          end
        RUBY
      end

      # Define the full execution flow here
      def execute_generator_steps
        check_and_install_devise
        check_and_install_theme_system
        create_user_model
        create_user_controller
        create_views
        create_partials
        add_routes
        setup_action_text
        create_components_table
        seed_components
        insert_action_text_component
        create_user_profile_bio_partial
        add_authorization_logic
      end

      # This is the method to be called when the generator is executed
      def generate_user
        execute_generator_steps
      end
    end
  end
end




# module Nevaeh
#   module Generators
#     class UserGenerator < Rails::Generators::Base
#       source_root File.expand_path('templates', __dir__)
#
#       # Override the default `generate` method
#             def generate
#               generate_user
#             end
#
#      private
#
#       def check_and_install_devise
#         unless defined?(Devise)
#           generate "devise:install"
#           generate "devise", "User"
#         end
#       end
#
#       def check_and_install_theme_system
#         unless ActiveRecord::Base.connection.table_exists?('themes')
#           generate "nevaeh:theme"
#           create_theme_model
#         end
#       end
#
#       def create_theme_model
#         generate "model", "Theme name:string font:string color_scheme:string"
#         rake "db:migrate"
#       end
#
#       def create_user_model
#         generate "migration", "AddFieldsToUsers name:string role:integer theme_id:integer"
#         inject_into_class "app/models/user.rb", "User", <<-RUBY
#           enum role: { admin: 0, editor: 1, user: 2 }
#           belongs_to :theme, optional: true
#           after_initialize :set_default_role
#
#           private
#           def set_default_role
#             self.role ||= :user
#           end
#         RUBY
#         rake "db:migrate"
#       end
#
#       def create_user_controller
#         create_file "app/controllers/users_controller.rb", <<-FILE
#           class UsersController < ApplicationController
#             before_action :set_user, only: [:show]
#
#             def index
#               @users = User.all
#               respond_to do |format|
#                 format.html
#                 format.json { render json: @users }
#               end
#             end
#
#             def show
#               respond_to do |format|
#                 format.html
#                 format.json { render json: @user }
#               end
#             end
#
#             private
#             def set_user
#               @user = User.find(params[:id])
#             end
#           end
#         FILE
#       end
#
#       def create_views
#         create_file "app/views/users/index.html.erb", <<-FILE
#           <h1>Users</h1>
#           <%= render partial: 'user_card', collection: @users, as: :user %>
#         FILE
#
#         create_file "app/views/users/show.html.erb", <<-FILE
#           <h1><%= @user.name %></h1>
#           <p>Role: <%= @user.role.capitalize %></p>
#           <%= @user.bio&.to_html %>
#         FILE
#       end
#
#       def create_partials
#         create_file "app/views/users/_user_card.html.erb", <<-FILE
#           <div class="user-card" style="font-family: <%= user.theme&.font %>; background-color: <%= user.theme&.color_scheme %>;">
#             <h2><%= user.name %></h2>
#             <p>Role: <%= user.role.capitalize %></p>
#           </div>
#         FILE
#       end
#
#       def add_routes
#         route "resources :users, only: [:index, :show]"
#       end
#
#       def setup_action_text
#         generate "action_text:install"
#         rake "db:migrate"
#       end
#
#       def create_components_table
#         generate "migration", "CreateComponents name:string component_type:string access_roles:text"
#         rake "db:migrate"
#       end
#
#       def seed_components
#         create_file "db/seeds/components.rb", <<-FILE
#           Component.create!(name: 'user_profile_bio', component_type: 'user', access_roles: ['admin', 'editor', 'user'])
#         FILE
#       end
#
#       def insert_action_text_component
#         create_file "app/models/user_component.rb", <<-FILE
#           class UserComponent < ApplicationRecord
#             has_rich_text :content
#
#             def render_html
#               content.body.to_s.gsub(/<user-profile-bio user_id=\"(\d+)\"\/>/) do
#                 user = User.find_by(id: $1)
#                 user && user.allowed_component?('user_profile_bio') ? ApplicationController.render(partial: 'users/profile_bio', locals: { user: user }) : ''
#               end
#             end
#
#             def render_json
#               { content: render_html }.to_json
#             end
#           end
#         FILE
#       end
#
#       def create_user_profile_bio_partial
#         create_file "app/views/users/_profile_bio.html.erb", <<-FILE
#           <div class="user-profile-bio">
#             <h2><%= user.name %></h2>
#             <p><%= user.bio %></p>
#           </div>
#         FILE
#       end
#
#       def add_authorization_logic
#         inject_into_class "app/models/user.rb", "User", <<-RUBY
#           def allowed_component?(component_name)
#             component = Component.find_by(name: component_name)
#             component && (component.access_roles.include?(self.role) || self.admin?)
#           end
#         RUBY
#       end
#
#       # Define the full execution flow here
#       def execute_generator_steps
#         check_and_install_devise
#         check_and_install_theme_system
#         create_user_model
#         create_user_controller
#         create_views
#         create_partials
#         add_routes
#         setup_action_text
#         create_components_table
#         seed_components
#         insert_action_text_component
#         create_user_profile_bio_partial
#         add_authorization_logic
#       end
#
#       # This is the method to be called when the generator is executed
#       def generate_user
#         execute_generator_steps
#       end
#     end
#   end
# end
