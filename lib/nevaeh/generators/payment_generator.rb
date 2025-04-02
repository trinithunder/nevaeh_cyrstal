module Nevaeh
  module Generators
    class PaymentGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Generates payment processing system linked to Shopping and Products."
      
      def install
        # Define the steps with their descriptions and corresponding methods
        step_items = [
          { step: "Step 1: Generate Payment model", action: "create_payment_model" },
          { step: "Step 2: Define payment methods", action: "create_payment_methods" },
          { step: "Step 3: Create Paypal Service", action: "create_paypal_service_file" },
          { step: "Step 4: Link Shopping with Payments", action: "link_shopping_to_payments" }
        ]

        # Loop through each step and dynamically call the associated method
        step_items.each do |item|
          say item[:step], :green
          send(item[:action])  # Dynamically calls the method based on the action name
        end
      end
      

      # def install
#         step_items = [{step:"Step 1: Generate Payment model",action:"create_payment_model"},]
#         say "Step 1: Generate Payment model", :green
#         create_payment_model
#         say "Step 2: Define payment methods", :green
#         create_payment_methods
#         say "Step 3: Create Paypal Service", :green
#         create_paypal_service_file()
#         say "Step 4: Link Shopping with Payments", :green
#         link_shopping_to_payments
#       end

      private

      # Step 1: Generate Payment model
      def create_payment_model
        generate "model", "Payment shopping:references status:string amount:decimal transaction_id:string payment_method:string response_data:text"
      end

      # Step 2: Define payment methods
      def create_payment_methods
        inject_into_class "app/models/payment.rb", "Payment" do
          <<-RUBY
          belongs_to :shopping
            serialize :response_data, JSON

            validates :amount, numericality: { greater_than: 0 }
            validates :payment_method, presence: true

            after_create :process_payment

            def process_payment
              case payment_method
              when "paypal"
                process_paypal
              when "stripe"
                process_stripe
              when "bank_transfer"
                process_bank_transfer
              else
                update(status: "failed", response_data: { error: "Unsupported payment method" })
              end
            end

            def approved?
              status == "approved"
            end

            private

            def process_paypal
              response = PayPalService.charge(amount, shopping.user.email)
              update(status: response[:status], transaction_id: response[:transaction_id], response_data: response)
            end

            def process_stripe
              response = StripeService.charge(amount, shopping.user.stripe_customer_id)
              update(status: response[:status], transaction_id: response[:transaction_id], response_data: response)
            end

            def process_bank_transfer
              response = BankTransferService.process_transfer(amount, shopping.user.bank_account)
              update(status: response[:status], transaction_id: response[:transaction_id], response_data: response)
            end
          RUBY
        end
      end

      # Step 3: Create Paypal Service
      def create_paypal_service_file(file_path)
        
        # Ensure the directory exists
          dir = File.dirname(file_path)
          Dir.mkdir(dir) unless Dir.exist?(dir)
          
        content = <<~RUBY
          class PayPalService
            require "faraday"

            PAYPAL_API_URL = "https://api-m.sandbox.paypal.com"  # Replace with live URL for production

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

        File.write(file_path, content)
      end
      
      # Step 4: Link Shopping with Payments
      def link_shopping_to_payments
        inject_into_class "app/models/shopping.rb", "Shopping" do
          <<-RUBY
            has_many :payments

            def checkout(payment_method)
              payment = payments.create(
                amount: total_value,
                payment_method: payment_method,
                status: "pending"
              )
              payment.process!
              payment.approved?
            end
          RUBY
        end
      end
      
      
    end
  end
end
