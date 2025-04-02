module Nevaeh
  module Generators
    class DefaultThemeGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)
      
      def run_actions
        install_devise
        create_user_model
        generate_dashboards
        create_dashboard_views
        setup_theme_model
        seed_default_users
        set_root_path
        configure_redirects
        run_scaffolds
        install_cancancan
        generate_mailer
      end
      
      private
      
      def install_devise
        gem 'devise'
        run "bundle install"
        generate "devise:install"
      end
      
      def create_user_model
        generate "devise User role:string"
        
        # Add roles to the User model
        inject_into_class "app/models/user.rb", "User" do
          "  enum role: { user: 0, admin: 1 }\n  after_initialize :set_default_role, if: :new_record?\n\n  private\n\n  def set_default_role\n    self.role ||= :user\n  end\n"
        end
      end
      
      def generate_dashboards
        generate "controller UsersDashboard index"
        generate "controller AdminDashboard index"
      
        # Set up authentication for dashboards
        inject_into_class "app/controllers/users_dashboard_controller.rb", "UsersDashboardController" do
          "  before_action :authenticate_user!\n  load_and_authorize_resource\n"
        end

        inject_into_class "app/controllers/admin_dashboard_controller.rb", "AdminDashboardController" do
          "  before_action :authenticate_user!\n  before_action :authorize_admin\n  load_and_authorize_resource\n\n  private\n\n  def authorize_admin\n    redirect_to root_path, alert: 'Not authorized.' unless current_user.admin?\n  end\n"
        end
      end
      
      def create_dashboard_views
        create_file "app/views/users_dashboard/index.html.erb" do
          "<h1>User Dashboard</h1>\n<p>Welcome, <%= current_user.email %></p>\n<style><%= Theme.current.css %></style>"
        end
        
        create_file "app/views/admin_dashboard/index.html.erb" do
          "<h1>Admin Dashboard</h1>\n<p>Admin Panel</p>\n<style><%= Theme.current.css %></style>"
        end
      end
      
      def setup_theme_model
        generate "model Theme name:string css:text"
        
        inject_into_class "app/models/theme.rb", "Theme" do
          "  def self.current\n    order(created_at: :desc).first || create(name: 'Default', css: '')\n  end\n"
        end
      end
      
      def seed_default_users
        append_to_file "db/seeds.rb" do
          "\nUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password', role: 'admin')\nUser.create!(email: 'user@example.com', password: 'password', password_confirmation: 'password', role: 'user')\nTheme.create!(name: 'Default', css: 'body { background-color: #f8f9fa; }')\n"
        end
      end
      
      def set_root_path
        route "root to: 'users_dashboard#index'"
      end
      
      def configure_redirects
        inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
          "  def after_sign_in_path_for(resource)\n    if resource.admin?\n      admin_dashboard_index_path\n    else\n      users_dashboard_index_path\n    end\n  end\n"
        end
      end
      
      def install_cancancan
        gem 'cancancan'
        run "bundle install"
        generate "cancan:ability"
      end

      def generate_mailer
        generate "mailer UserMailer welcome_email password_reset"
        
        create_file "app/views/user_mailer/welcome_email.html.erb" do
          "<h1>Welcome to Our Platform</h1>\n<p>Thank you for signing up, <%= @user.email %>!</p>"
        end

        create_file "app/views/user_mailer/password_reset.html.erb" do
          "<h1>Password Reset</h1>\n<p>Click <a href='<%= @reset_link %>'>here</a> to reset your password.</p>"
        end

        inject_into_class "app/mailers/user_mailer.rb", "UserMailer" do
          "  def welcome_email(user)\n    @user = user\n    mail(to: @user.email, subject: 'Welcome to Our Platform')\n  end\n\n  def password_reset(user, reset_link)\n    @user = user\n    @reset_link = reset_link\n    mail(to: @user.email, subject: 'Reset Your Password')\n  end\n"
        end
      end
      
      # def run_scaffolds(models = ["val1", "val2", "val3"])
#         models.each { |model| create_scaffold(model) }
#       end
      
def run_scaffolds
  models = ["home", "page",]
  models.each {|model| create_scaffold(model)}
end

      def create_scaffold(model)
        model_name = model.camelize.singularize

        # Generates the scaffold with title and content attributes
        generate "scaffold", "#{model_name} title:string content:text"

        # Add `has_rich_text :content` to the model
        inject_into_class "app/models/#{model}.rb", model_name do
          "  has_rich_text :content\n"
        end

        # Remove the text column from the migration
        remove_text_content_column(model)

        # Update form and show views
        update_form(model)
        update_show_view(model)
      end

      def remove_text_content_column(model)
        migration_file = Dir.glob("db/migrate/*_create_#{model.pluralize}.rb").first
        return unless migration_file

        gsub_file migration_file, /t.text :content/, "# t.text :content  # Replaced by Action Text"
      end

      def update_form(model)
        gsub_file "app/views/#{model.pluralize}/_form.html.erb",
                  /<%= form.text_area :content %>/,
                  "<%= form.rich_text_area :content %>"
      end

      def update_show_view(model)
        gsub_file "app/views/#{model.pluralize}/show.html.erb",
                  /<%= @#{model}.content %>/,
                  "<%= @#{model}.content.to_s.html_safe %>"
      end
      

    end
  end
end



