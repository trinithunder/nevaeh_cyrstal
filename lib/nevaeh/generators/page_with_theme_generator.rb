module Nevaeh
  module Generators
    # This will generate a page with a default header component, which you can then customize further.    #
    #
    # 5. Rendering the Theme Based on Parameters
    # If you have a Theme model that defines the overall look and feel, you could use this to dynamically style your components based on the user’s theme. For example:
    
    class PageWithThemeGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      def run_actions(page_name,page_theme)
        create_page(page_name,page_theme)
      end

      private
      
      def create_page(page_name,page_theme)
        @page = Page.create!(
          name: '#{page_name}',
          theme: Theme.find_by(name: '#{page_theme}')
        )

        # Insert default components into the content
        @page.update!(content: "<component name='header' params='{\"content\": \"Welcome to the Site!\"}'></component>")
      end
      
      def make_model
        class Theme < ApplicationRecord
          has_many :pages
  
          def apply_styles(content)
            # Apply theme styles to the content
            "<div class='theme-#{self.name}'>#{content}</div>"
          end
        end
        
        
      end
      
    end
  end
end
