# lib/generators/nevaeh_crystal/system_install_generator.rb
module Nevaeh
  module Generators
    class SystemInstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def install
        say "Starting installation...", :green

        @application_name = ask("What is the name of this application?", :yellow).downcase
        @secure_pw = ask("What password do you want to secure your application?", :yellow)
  
        setup_dotenv
        db_choice = ask("Which database do you want to use? (postgresql/mysql/mongodb/redis/sqlite)", :yellow).downcase
        setup_database(db_choice)

        check_and_install_devise
        setup_cancancan
        create_seed_users
        install_blog

        say "Installation complete!", :green
      end
      
      
      private
      
      def add_gem_unless_present(gem_name)
        gemfile = File.read("Gemfile")
        if gemfile.include?(%("#{gem_name}")) || gemfile.include?(gem_name)
          say_status :skip, "#{gem_name} already present in Gemfile", :yellow
        else
          run "bundle add #{gem_name}"
        end
      end
      

      def setup_dotenv
        say "Adding dotenv-rails for environment variable management...", :green
        add_dotenv
        run "bundle install"

        unless File.exist?(Rails.root.join(".env"))
          create_file ".env", <<~ENV
            # Database credentials
            DB_USERNAME=#{@application_name}
            DB_PASSWORD=#{@secure_pw}
            REDIS_URL=redis://localhost:6379/1
          ENV
        end

        say ".env file created! Be sure to add it to .gitignore.", :yellow
      end
      



      def add_dotenv
        gemfile = File.read("Gemfile")
        unless gemfile.include?("dotenv-rails")
          add_gem_unless_present("dotenv-rails")
        else
          say_status :skip, "dotenv-rails already present in Gemfile", :yellow
        end
      end


def create_db_creds
  create_file ".env", <<-ENV
      # Database credentials
      DB_USERNAME=#{application_name}
      DB_PASSWORD=#{secure_pw}
      REDIS_URL=redis://localhost:6379/1
            ENV

end
      
      def setup_database(db_choice)
        case db_choice
        when "postgresql"
          configure_postgresql
        when "mysql"
          configure_mysql
        when "mongodb"
          configure_mongodb
        when "redis"
          configure_redis
        else
          say "Unsupported or no choice detected. Keeping default SQLite setup.", :yellow
        end
      end

      def configure_postgresql
        say "Configuring PostgreSQL...", :green
        add_gem_unless_present("pg")
        run "bundle install"
        update_database_yml("postgresql", "pg")

        # Create database user if not exists
        run %Q{psql -U postgres -c "DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '#{ENV['DB_USERNAME']}') THEN CREATE ROLE #{ENV['DB_USERNAME']} WITH LOGIN PASSWORD '#{ENV['DB_PASSWORD']}'; ALTER ROLE #{ENV['DB_USERNAME']} CREATEDB; END IF; END $$;"}

        run "rails db:create db:migrate"
      end
      
      def configure_mysql
        say "Configuring MySQL...", :green
        add_gem_unless_present("mysql2")
        run "bundle install"
        update_database_yml("mysql2", "mysql2")

        # Create database user if not exists
        run %Q{mysql -u root -e "CREATE USER IF NOT EXISTS '#{ENV['DB_USERNAME']}'@'localhost' IDENTIFIED BY '#{ENV['DB_PASSWORD']}'; GRANT ALL PRIVILEGES ON *.* TO '#{ENV['DB_USERNAME']}'@'localhost' WITH GRANT OPTION;"}

        run "rails db:create db:migrate"
      end
      

      def configure_mongodb
        say "Configuring MongoDB...", :green
        add_gem_unless_present("mongoid")
        run "bundle install"
        run "rails generate mongoid:config"

        # Modify the Mongoid configuration file for authentication
        mongoid_config = <<-YAML
        development:
          clients:
            default:
              uri: mongodb://#{ENV['DB_USERNAME']}:#{ENV['DB_PASSWORD']}@localhost:27017/myapp_development?authSource=admin
        production:
          clients:
            default:
              uri: mongodb://#{ENV['DB_USERNAME']}:#{ENV['DB_PASSWORD']}@localhost:27017/myapp_production?authSource=admin
        YAML

        File.write(Rails.root.join("config", "mongoid.yml"), mongoid_config)
      end
      

      def configure_redis
        say "Configuring Redis...", :green
        add_gem_unless_present("redis")
        run "bundle install"
        create_redis_initializer
      end

      def update_database_yml(adapter, gem_name)
        database_config = <<-YAML
    default: &default
      adapter: #{adapter}
      encoding: unicode
      pool: 5
      username: <%= ENV['DB_USERNAME'] %>
      password: <%= ENV['DB_PASSWORD'] %>

    development:
      <<: *default
      database: myapp_development

    test:
      <<: *default
      database: myapp_test

    production:
      <<: *default
      database: myapp_production
        YAML

        File.write(Rails.root.join("config", "database.yml"), database_config)
      end

      def create_redis_initializer
        redis_config = <<-RUBY
    Redis.current = Redis.new(url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" })
        RUBY

        File.write(Rails.root.join("config", "initializers", "redis.rb"), redis_config)
      end

      def check_and_install_devise
        unless defined?(Devise)
          add_gem_unless_present("devise")
          run "bundle install"
          generate "devise:install"
          generate "devise User role:integer"
          run "rails generate devise:views"
          say "Devise installed and user model generated!", :green
        end
      end

      def setup_cancancan
        add_gem_unless_present("cancancan")
        run "bundle install"
        generate "cancan:ability"

        ability_rules = <<-RUBY
    class Ability
      include CanCan::Ability

      def initialize(user)
        user ||= User.new(role: 0) # Default role is user (0)

        if user.role >= 8
          can :manage, :all
        elsif user.role >= 5
          can :manage, User
          can :manage, Post
        elsif user.role >= 3
          can :manage, Comment
          can :read, Post
          can :read, Article, published_at: ..Time.current # Allow users to see only published articles
          can :create, Article if user.persisted? # Allow logged-in users to create articles
          can :update, Article, user_id: user.id, published_at: ..Time.current # Allow users to edit their own published articles
          cannot :update, Article, published_at: ->(time) { time.future? } # Prevent modifying scheduled articles
        else
          can :read, Post
        end
      end
    end
        RUBY

        File.write(Rails.root.join("app", "models", "ability.rb"), ability_rules)
        say "Cancancan installed and ability.rb rules generated!", :green
      end

      def create_seed_users
        say "Seeding default users...", :green
        seed_data = <<-RUBY
    User.create!(email: "default@site.com", password: "password123", role: 0)
    User.create!(email: "mrlightek@lightek.com", password: "CrystalL!ghtek20", role: 8)
        RUBY

        File.write(Rails.root.join("db", "seeds.rb"), seed_data)
        run "rails db:seed"
      end
      
      def install_blog
        add_gem_unless_present("nokogiri")
        generate "nevaeh:blog"
      end
    end
    
    end
  end