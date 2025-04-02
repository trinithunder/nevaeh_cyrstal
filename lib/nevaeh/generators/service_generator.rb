module Nevaeh
  module Generators
    # lib/generators/nevaeh/service/service_generator.rb
    require "rails/generators"

    class ServiceGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      desc "This allows you to specify services via the command line, like so:
      <br>
      rails g nevaeh:service:install_services pay_pal stripe
      "

      # The generator call, which installs the services.
      def install_services
        services = ARGV.empty? ? ["pay_pal", "stripe", "generic"] : ARGV
        services.each { |service_name| create_service_file(service_name) }
      end
      

      private

      # Creates individual service files based on the name provided
      def create_service_file(service_name, directory = "app/services")
        # Ensure the directory exists
        Dir.mkdir(directory) unless Dir.exist?(directory)

        # Format the class name to CamelCase
        class_name = service_name.split('_').map(&:capitalize).join

        # Define different content based on the service name
        content = case service_name
                  when "pay_pal"
                    <<~RUBY
                      class #{class_name}Service
                        require "faraday"

                        PAYPAL_API_URL = "https://api-m.sandbox.paypal.com"

                        def self.charge(amount, email)
                          response = Faraday.post("\#{PAYPAL_API_URL}/v2/checkout/orders") do |req|
                            req.headers["Content-Type"] = "application/json"
                            req.headers["Authorization"] = "Bearer \#{ENV['PAYPAL_ACCESS_TOKEN']}"
                            req.body = {
                              intent: "CAPTURE",
                              purchase_units: [{ amount: { currency_code: "USD", value: amount } }],
                              payer: { email_address: email }
                            }.to_json
                          end

                          if response.success?
                            json = JSON.parse(response.body)
                            { status: "approved", transaction_id: json["id"], response: json }
                          else
                            { status: "failed", error: response.body }
                          end
                        end
                      end
                    RUBY
                  when "stripe"
                    <<~RUBY
                      class #{class_name}Service
                        require "stripe"

                        def self.charge(amount, token)
                          Stripe.api_key = ENV['STRIPE_SECRET_KEY']
                    
                          charge = Stripe::Charge.create(
                            amount: (amount.to_f * 100).to_i, # Convert to cents
                            currency: "usd",
                            source: token,
                            description: "Charge for service"
                          )

                          { status: "approved", transaction_id: charge.id, response: charge }
                        rescue Stripe::CardError => e
                          { status: "failed", error: e.message }
                        end
                      end
                    RUBY
                  else
                    <<~RUBY
                      class #{class_name}Service
                        def initialize
                          # Initialize dependencies if needed
                        end

                        def call
                          # Business logic goes here
                        end
                      end
                    RUBY
                  end

        # Define the file path where the service will be saved
        file_path = "#{directory}/#{service_name}_service.rb"

        # Write the content to the file
        File.write(file_path, content)

        puts "Service file created at: #{file_path}"
      end
    end
  end
end
