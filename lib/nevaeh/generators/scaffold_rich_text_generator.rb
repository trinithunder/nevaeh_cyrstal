# class ScaffoldRichTextGenerator < Rails::Generators::NamedBase
#   source_root File.expand_path("templates", __dir__)
# end


module Nevaeh
  module Generators
    class ScaffoldRichTextGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_scaffold
        # Generates the scaffold with title and content attributes
        generate "scaffold", "#{file_name} title:string content:text"

        # Add `has_rich_text :content` to the model
        inject_into_class "app/models/#{file_name}.rb", file_name.classify do
          "  has_rich_text :content\n"
        end

        # Remove the text column from the migration
        remove_text_content_column

        # Update the form view
        update_form

        # Update the show view
        update_show_view
      end

      private

      def remove_text_content_column
        migration_file = Dir.glob("db/migrate/*_create_#{file_name.pluralize}.rb").first
        if migration_file
          gsub_file migration_file, /t.text :content/, "# t.text :content  # Replaced by Action Text"
        end
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
    end
  end
end
