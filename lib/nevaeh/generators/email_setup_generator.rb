module Nevaeh
  module Generators
    
    # class EmailSetupGenerator < Rails::Generators::NamedBase
    #   source_root File.expand_path("templates", __dir__)
    # end

    # lib/generators/email_setup/email_setup_generator.rb

    class EmailSetupGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      # Provide a description for your generator
       desc "Sets up email configuration for your Rails app"

       # Argument example (optional)
       argument :email_provider, type: :string, default: "sendgrid", banner: "EMAIL_PROVIDER"

       # Class options example (optional)
       class_option :enable_smtp, type: :boolean, default: true, desc: "Enable SMTP configuration"

      def create_email_config_files
        copy_file "config/initializers/email_initializer.rb", "config/initializers/email_initializer.rb"
        copy_file "config/mailers/application_mailer.rb", "app/mailers/application_mailer.rb"
      end

      def install_email_dependencies
        gem "mail", "~> 2.7"
        gem "sendgrid-ruby", "~> 6.7.1" # Example for SendGrid; replace with your server if different
        run "bundle install"
      end
      
      def run_all_tasks
        invoke :create_email_config_files
        invoke :install_email_dependencies
      end
    end
    
    
  end
end