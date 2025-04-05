# lib/generators/nevaeh/apache_vhost/apache_vhost_generator.rb
require 'rails/generators'

module Nevaeh
  module Generators
    class ApacheVhostGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      argument :domain, type: :string
      argument :document_root, type: :string
      class_option :ssl, type: :boolean, default: false

      def create_service_file
        # Ensure directories exist
        create_file 'lib/services/apache_vhost_service.rb', apache_vhost_service_content
      end

      def create_apache_vhost
        say("Generating Apache vhost for #{domain}...", :green)

        # Now use the service to create the vhost file
        ApacheVhostService.new(
          domain: domain,
          document_root: document_root,
          ssl: options[:ssl]
        ).create_vhost

        say("Apache vhost created and enabled for #{domain}", :green)
      end

      private

      def apache_vhost_service_content
        <<-FILE
# lib/services/apache_vhost_service.rb
class ApacheVhostService
  APACHE_SITES_AVAILABLE = "/etc/apache2/sites-available/"
  APACHE_SITES_ENABLED = "/etc/apache2/sites-enabled/"

  def initialize(domain:, document_root:, ssl: false)
    @domain = domain
    @document_root = document_root
    @ssl = ssl
  end

  def create_vhost
    vhost_content = generate_vhost_config
    vhost_file = "#{APACHE_SITES_AVAILABLE}#{@domain}.conf"
    File.write(vhost_file, vhost_content)
    enable_site
    reload_apache
  end

  private

  def generate_vhost_config
    <<~EOF
      <VirtualHost *:80>
          ServerName #{@domain}
          DocumentRoot #{@document_root}

          <Directory #{@document_root}>
              AllowOverride All
              Require all granted
          </Directory>

          ErrorLog ${APACHE_LOG_DIR}/#{@domain}_error.log
          CustomLog ${APACHE_LOG_DIR}/#{@domain}_access.log combined
      </VirtualHost>
    EOF
  end

  def enable_site
    system("a2ensite #{@domain}.conf")
  end

  def reload_apache
    system("systemctl reload apache2")
  end
end
        FILE
      end
    end
  end
end




# module Nevaeh
#   module Generators
#
#     class ApacheVhostGenerator < Rails::Generators::NamedBase
#       APACHE_SITES_AVAILABLE = "/etc/apache2/sites-available/"
#       APACHE_SITES_ENABLED = "/etc/apache2/sites-enabled/"
#
#       def initialize(domain:, document_root:, ssl: false)
#         @domain = domain
#         @document_root = document_root
#         @ssl = ssl
#       end
#
#       def create_vhost
#         vhost_content = generate_vhost_config
#         vhost_file = "#{APACHE_SITES_AVAILABLE}#{@domain}.conf"
#         File.write(vhost_file, vhost_content)
#         enable_site(vhost_file)
#         reload_apache
#       end
#
#       private
#
#       def generate_vhost_config
#         <<-EOF
#   <VirtualHost *:80>
#       ServerName #{@domain}
#       DocumentRoot #{@document_root}
#
#       <Directory #{@document_root}>
#           AllowOverride All
#           Require all granted
#       </Directory>
#
#       ErrorLog ${APACHE_LOG_DIR}/#{@domain}_error.log
#       CustomLog ${APACHE_LOG_DIR}/#{@domain}_access.log combined
#   </VirtualHost>
#         EOF
#       end
#
#       def enable_site(vhost_file)
#         system("a2ensite #{@domain}.conf")
#       end
#
#       def reload_apache
#         system("systemctl reload apache2")
#       end
#     end
#
#     included do
#       def apache_vhost_service(domain:, document_root:, ssl: false)
#         ApacheVhostService.new(domain: domain, document_root: document_root, ssl: ssl)
#       end
#     end
#
#   end
# end
#
#
#
# module ApacheVhostConcern
#   extend ActiveSupport::Concern
#
#   class ApacheVhostService
#     APACHE_SITES_AVAILABLE = "/etc/apache2/sites-available/"
#     APACHE_SITES_ENABLED = "/etc/apache2/sites-enabled/"
#
#     def initialize(domain:, document_root:, ssl: false)
#       @domain = domain
#       @document_root = document_root
#       @ssl = ssl
#     end
#
#     def create_vhost
#       vhost_content = generate_vhost_config
#       vhost_file = "#{APACHE_SITES_AVAILABLE}#{@domain}.conf"
#       File.write(vhost_file, vhost_content)
#       enable_site(vhost_file)
#       reload_apache
#     end
#
#     private
#
#     def generate_vhost_config
#       <<-EOF
# <VirtualHost *:80>
#     ServerName #{@domain}
#     DocumentRoot #{@document_root}
#
#     <Directory #{@document_root}>
#         AllowOverride All
#         Require all granted
#     </Directory>
#
#     ErrorLog ${APACHE_LOG_DIR}/#{@domain}_error.log
#     CustomLog ${APACHE_LOG_DIR}/#{@domain}_access.log combined
# </VirtualHost>
#       EOF
#     end
#
#     def enable_site(vhost_file)
#       system("a2ensite #{@domain}.conf")
#     end
#
#     def reload_apache
#       system("systemctl reload apache2")
#     end
#   end
#
#   included do
#     def apache_vhost_service(domain:, document_root:, ssl: false)
#       ApacheVhostService.new(domain: domain, document_root: document_root, ssl: ssl)
#     end
#   end
# end
