# lib/generators/nevaeh_crystal/system_setting_generator.rb
#TODO: Comeback and setup site work from apache in here so users can have individual sites/host themselves.
#TODO: Add in installing the lte/5G servers and work in here
#TODO:Set up email server set up in here
require "securerandom"
require "yaml"


module Nevaeh
  module Generators
    class SystemSettingGenerator < Rails::Generators::Base
      argument :database_type, type: :string, default: "postgresql"

      def setup_environment
        # write_db_credentials
#         install_database
#         create_database_user
#         setup_devise
#         setup_cancancan
#         seed_users
          system_install
      end

      private

      def system_install
        generate "nevaeh:system_install"
      end
        
      def write_db_credentials
        db_user = "sys_user_#{SecureRandom.hex(4)}"
        db_password = SecureRandom.hex(16)

        credentials = { "db_user" => db_user, "db_password" => db_password }
        db_users_file = Rails.root.join("config", "seeds", "db_users.yml")

        File.write(db_users_file, credentials.to_yaml)

        say "Database credentials written to #{db_users_file}", :green
      end

      def install_database
        case database_type
        when "postgresql"
          install_postgresql
        when "mysql", "mariadb"
          install_mysql
        when "sqlite"
          install_sqlite
        when "mongodb"
          install_mongodb
        when "redis"
          install_redis
        else
          say "Unsupported database type: #{database_type}", :red
          exit(1)
        end
      end

      def create_database_user
        return if database_type == "sqlite" || database_type == "redis" || database_type == "mongodb"

        db_users_file = Rails.root.join("config", "seeds", "db_users.yml")
        seed_data = YAML.load_file(db_users_file)

        db_user = seed_data["db_user"]
        db_password = seed_data["db_password"]

        say "Creating database user: #{db_user}", :green

        case database_type
        when "postgresql"
          execute_sql("CREATE USER #{db_user} WITH PASSWORD '#{db_password}';")
          execute_sql("ALTER ROLE #{db_user} CREATEDB;")
        when "mysql", "mariadb"
          execute_sql("CREATE USER '#{db_user}'@'localhost' IDENTIFIED BY '#{db_password}';")
          execute_sql("GRANT ALL PRIVILEGES ON *.* TO '#{db_user}'@'localhost';")
        end
      end

      def setup_devise
        add_gem("devise")
        run "bundle install"

        generate "devise:install"
        generate "devise", "User", "role:integer"

        # Set default role to 0
        inject_into_file "db/migrate/*_devise_create_users.rb", 
          "      t.integer :role, default: 0\n", 
          after: "## Custom fields\n"

        rake "db:migrate"
      end

      def setup_cancancan
        add_gem("cancancan")
        run "bundle install"

        generate "cancan:ability"
        say "Cancancan installed and ability.rb generated!", :green
        
        # Define role-based permissions in Ability.rb
          update_ability_file
      end
      
      def update_ability_file
        ability_file = Rails.root.join("app/models/ability.rb")

        rules = <<-RUBY
      class Ability
        include CanCan::Ability

        def initialize(user)
          user ||= User.new(role: 0) # Default to guest (role: 0)

          case user.role
          when 0 # User
      # A user can only manage their own posts, articles, and blogs
      can :read, Post, user_id: user.id
      can :read, Article, user_id: user.id
      can :read, Blog, user_id: user.id
      can [:create, :update, :destroy], Post, user_id: user.id
      can [:create, :update, :destroy], Article, user_id: user.id
      can [:create, :update, :destroy], Blog, user_id: user.id

          when 3 # Moderator
      # A moderator can read and update all posts, articles, and blogs
      can [:read, :update], Post
      can [:read, :update], Article
      can [:read, :update], Blog
      # A moderator cannot delete anything
      cannot :destroy, Post
      cannot :destroy, Article
      cannot :destroy, Blog

          when 5 # Admin
      # Admin can manage everything, but can't touch the God account
      can :manage, :all
      cannot :manage, User, role: 8 # Cannot manage the God account

          when 8 # Creator/God Account
      # The God account (Creator) can do everything
      can :manage, :all
          end
        end
      end
        RUBY

        File.write(ability_file, rules)
        say "Permissions added to Ability.rb!", :green
      end

      def seed_users
        append_to_file "db/seeds.rb" do
          <<-RUBY

    # Default User
    User.create!(
      email: "default@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: 0
    )

    # God Account
    User.create!(
      email: "mrlightek@lightek.com",
      password: "CrystalL!ghtek20",
      password_confirmation: "CrystalL!ghtek20",
      role: 8
    )

          RUBY
        end

        rake "db:seed"
        say "Users seeded successfully!", :green
      end

      def install_postgresql
        say "Installing PostgreSQL...", :green
        system("sudo apt update && sudo apt install -y postgresql postgresql-contrib")
      end

      def install_mysql
        say "Installing MySQL/MariaDB...", :green
        system("sudo apt update && sudo apt install -y mysql-server") if database_type == "mysql"
        system("sudo apt update && sudo apt install -y mariadb-server") if database_type == "mariadb"
      end

      def install_sqlite
        say "Installing SQLite...", :green
        system("sudo apt update && sudo apt install -y sqlite3 libsqlite3-dev")
      end

      def install_mongodb
        say "Installing MongoDB...", :green
        system("sudo apt update && sudo apt install -y mongodb-org")
        system("sudo systemctl start mongod && sudo systemctl enable mongod")
      end

      def install_redis
        say "Installing Redis...", :green
        system("sudo apt update && sudo apt install -y redis")
        system("sudo systemctl start redis && sudo systemctl enable redis")
      end

      def execute_sql(command)
        case database_type
        when "postgresql"
          system("sudo -u postgres psql -c \"#{command}\"")
        when "mysql", "mariadb"
          system("mysql -u root -e \"#{command}\"")
        end
      end

      def add_gem(gem_name)
        gemfile = Rails.root.join("Gemfile")
        unless File.readlines(gemfile).grep(/#{gem_name}/).any?
          append_to_file gemfile, "\ngem '#{gem_name}'"
        end
      end
    end
    
    
  end
end