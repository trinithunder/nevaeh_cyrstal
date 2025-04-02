module Nevaeh
  module Generators
    class BaseInstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      argument :database_type, type: :string, default: "postgresql"
      
      desc "Base site install all wrapped into one!."
      
      def install
        # Define the steps with their descriptions and corresponding methods
        step_items = [
          { step: "Step 1: Installing system settings", action: "install_system_setting" },
          { step: "Step 2: Creating files for making user and theme", action: "install_user_theme" },
          { step: "Step 3: Installing media_gallery", action: "install_media_gallery" },
          { step: "Step 4: Installing shopping", action: "install_shopping" },
          { step: "Step 5: Installing streaming", action: "install_streaming" }
        ]

        # Loop through each step and dynamically call the associated method
        step_items.each do |item|
          say item[:step], :green
          send(item[:action])  # Dynamically calls the method based on the action name
        end
      end
      
      private
      
      def install_system_setting
        generate "nevaeh:system_setting",:green
      end
      
      def install_user_theme
        generate "nevaeh:user",:green
      end
      
      def install_blog_system
        generate "nevaeh:blog"
      end
      
      def install_media_gallery
        generate "nevaeh:media_gallery",:green
      end
      
      def install_shopping
        generate "nevaeh:shopping",:green
      end
      
      def install_streaming
        generate "nevaeh:streaming",:green
      end
      
      
    end
  end
end