require "rails/generators"

module Nevaeh
  module Generators
    
    
    class Themeable < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_directories
        say "Creating necessary directories", :green
        run "mkdir -p lib/generators/themeable/templates/models"
        run "mkdir -p lib/generators/themeable/templates/controllers"
        run "mkdir -p lib/generators/themeable/templates/services"
        run "mkdir -p lib/generators/themeable/templates/concerns"
      end

      def create_theme_model
        say "Creating Theme model", :green
        create_file "lib/generators/themeable/templates/models/theme.rb", <<-RUBY
    class Theme < ApplicationRecord
      has_many :css_settings, dependent: :destroy
    end
        RUBY
      end

      def create_fastlane_service
        install_fastlane
        say "Creating Fastlane service", :green
        create_file "lib/generators/themeable/templates/services/fastlane_service.rb", <<-RUBY
    module FastlaneConcern
      extend ActiveSupport::Concern

      class FastlaneService
        attr_accessor :use_match, :use_snapshot, :use_scan, :use_gym, :use_supply, :use_pilot, :platform

        def initialize(platform: :ios, use_match: true, use_snapshot: false, use_scan: true, use_gym: true, use_supply: false, use_pilot: true)
          @platform = platform.to_sym
          @use_match = use_match
          @use_snapshot = use_snapshot
          @use_scan = use_scan
          @use_gym = use_gym
          @use_supply = use_supply
          @use_pilot = use_pilot
        end

        def test_lane
          command = "bundle exec fastlane \#{platform} test"
          run_fastlane(command)
        end

        def release_lane
          command = "bundle exec fastlane \#{platform} release"
          run_fastlane(command)
        end

        private

        def run_fastlane(command)
          env_vars = {
            "USE_MATCH" => @use_match.to_s,
            "USE_SNAPSHOT" => @use_snapshot.to_s,
            "USE_SCAN" => @use_scan.to_s,
            "USE_GYM" => @use_gym.to_s,
            "USE_SUPPLY" => @use_supply.to_s,
            "USE_PILOT" => @use_pilot.to_s
          }
          system(env_vars, command)
        end
      end

      included do
        def fastlane_service
          @fastlane_service ||= FastlaneService.new
        end
      end
    end
        RUBY
      end

      def create_fastlane_controller
        say "Creating Fastlane controller", :green
        create_file "lib/generators/themeable/templates/controllers/fastlane_controller.rb", <<-RUBY
    class FastlaneController < ApplicationController
      include FastlaneConcern

      def test
        platform = params[:platform] || "ios"
        fastlane_service = FastlaneService.new(platform: platform.to_sym)
        if fastlane_service.test_lane
          log_event("Test build triggered for \#{platform}")
          render json: { status: "Test build triggered successfully" }, status: :ok
        else
          log_event("Failed to trigger test build for \#{platform}", :error)
          render json: { error: "Failed to trigger test build" }, status: :unprocessable_entity
        end
      end

      def release
        platform = params[:platform] || "ios"
        fastlane_service = FastlaneService.new(platform: platform.to_sym)
        if fastlane_service.release_lane
          log_event("Release build triggered for \#{platform}")
          render json: { status: "Release build triggered successfully" }, status: :ok
        else
          log_event("Failed to trigger release build for \#{platform}", :error)
          render json: { error: "Failed to trigger release build" }, status: :unprocessable_entity
        end
      end
      
      def staging
        platform = params[:platform] || "ios"
        fastlane_service = FastlaneService.new(platform: platform.to_sym)
        if fastlane_service.staging_lane
          log_event("Staging build triggered for \#{platform}")
          render json: { status: "Staging build triggered successfully" }, status: :ok
        else
          log_event("Failed to trigger staging build for \#{platform}", :error)
          render json: { error: "Failed to trigger staging build" }, status: :unprocessable_entity
        end
      end
      
      def main
        platform = params[:platform] || "ios"
        fastlane_service = FastlaneService.new(platform: platform.to_sym)
        if fastlane_service.main_lane
          log_event("Main build triggered for \#{platform}")
          render json: { status: "Main build triggered successfully" }, status: :ok
        else
          log_event("Failed to trigger main build for \#{platform}", :error)
          render json: { error: "Failed to trigger main build" }, status: :unprocessable_entity
        end
      end
      
      def production
        platform = params[:platform] || "ios"
        fastlane_service = FastlaneService.new(platform: platform.to_sym)
        if fastlane_service.production_lane
          log_event("Production build triggered for \#{platform}")
          render json: { status: "Production build triggered successfully" }, status: :ok
        else
          log_event("Failed to trigger production build for \#{platform}", :error)
          render json: { error: "Failed to trigger production build" }, status: :unprocessable_entity
        end
      end

      private

      def log_event(message, level = :info)
        Rails.logger.send(level, message)
      end
    end
        RUBY
      end

      def add_routes
        say "Adding routes for themes", :green
        route <<-RUBY
    resources :themes, only: [] do
      collection do
        post :switch
      end
    end
        RUBY
      end
  
      # New method to install Fastlane
        def install_fastlane
          say "Installing Fastlane", :green

          # Add Fastlane gem to the Gemfile
          inject_into_file "Gemfile", after: "gem 'rails'" do
            "\ngem 'fastlane'"
          end

          # Run bundle install to install Fastlane
          run "bundle install"

          # Set up Fastlane for iOS (adjust if using Android or other platforms)
          say "Setting up Fastlane for iOS", :green
          run "fastlane init ios"

          # You can adjust this if you need to generate a specific Fastfile or lane setup.
          say "Fastlane setup complete", :green
        end
    
    end
    
  end
end
