    # class InstallScaffoldRichTextGenerator < Rails::Generators::Base
    #   source_root File.expand_path("templates", __dir__)
    #   desc "Installs required dependencies for scaffold_rich_text"
    #
    #   def add_gems
    #     gemfile_content = <<~RUBY
    #
    #       # Dependencies for scaffold_rich_text
    #       gem "actiontext"
    #       gem "cancancan"
    #       gem "faraday"
    #       gem "oj"
    #       gem "devise"
    #     RUBY
    #
    #     append_to_file "Gemfile", gemfile_content
    #   end
    #
    #   def install_action_text
    #     run "bundle install"
    #     run "rails action_text:install"
    #     run "rails g devise:install"
    #     run "rails g devise:views"
    #     run "rails g devise User"
    #     run "rails db:migrate"
    #   end
    # end
    
    
    
    module Nevaeh
      module Generators
        class InstallScaffoldRichTextGenerator < Rails::Generators::Base
          desc "Installs required dependencies for scaffold_rich_text"

          def add_gems
            gemfile_content = <<~RUBY

              # Dependencies for scaffold_rich_text
              gem "actiontext"
              gem "cancancan"
              gem "faraday"
              gem "oj"
              gem "devise"
            RUBY

            append_to_file "Gemfile", gemfile_content
          end

          def install_action_text
            run "bundle install"
            run "rails g action_text:install"
            run "bundle install"
            run "rails db:migrate"
            run "rails g devise:install"
            run "rails g devise:views"
            run "rails g devise User"
            run "rails db:migrate"
          end
          
          def run_all_tasks
                  invoke :add_gems
                  invoke :install_action_text
                end
                
        end
      end
    end
    