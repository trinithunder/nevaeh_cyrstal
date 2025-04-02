module Nevaeh
  module Generators
    class ShoppingGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      # Description of what this generator does
            desc "Generates a shopping system with Product and Shopping models, including metadata storage with ActionText."

            def install
              say "Step 1: Generate models for Shopping and Product", :green
              create_product_model
              say "Step 2: Define methods for product behavior", :green
              create_product_methods
              say "Step 3: Create Shopping model (handles carts, orders, etc.)", :green
              create_shopping_model
              say "Step 4: Define methods for Shopping behavior", :green
              create_shopping_methods
              say "Step 5: Add ActionText to Product for metadata", :green
              add_action_text_to_product
              say "Step 6: Connect Shopping to Payment Processing", :green
              connect_shopping_to_payments
            end
     
     private
      # Step 1: Generate models for Shopping and Product
      def create_product_model
        generate "model", "Product name:string price:decimal stock:integer sku:string shopping:references"
        generate "action_text:install"
        generate "migration AddMetadataToProducts metadata:text"
      end

      # Step 2: Define methods for product behavior
      def create_product_methods
        inject_into_class "app/models/product.rb", "Product" do
          <<-RUBY
            belongs_to :shopping
            has_rich_text :metadata  # ActionText for storing product metadata
            
            validates :name, presence: true
            validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
            validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

            # Checks if the product is in stock
            def in_stock?
              stock > 0
            end

            # Purchase logic (reduces stock)
            def purchase(quantity = 1)
              return false if stock < quantity
              decrement!(:stock, quantity)
            end

            # Predefined commands for product management
            def predefined_commands
              {
                update_price: "rails runner 'Product.find_by(sku: \"SKU123\").update(price: 19.99)'",
                restock: "rails runner 'Product.find_by(sku: \"SKU123\").increment!(:stock, 10)'"
              }
            end
          RUBY
        end
      end

      # Step 3: Create Shopping model (handles carts, orders, etc.)
      def create_shopping_model
        generate "model", "Shopping name:string description:text user:references"
      end

      # Step 4: Define methods for Shopping behavior
      def create_shopping_methods
        inject_into_class "app/models/shopping.rb", "Shopping" do
          <<-RUBY
            belongs_to :user
            has_many :products

            # Returns total value of all products in shopping
            def total_value
              products.sum { |p| p.price * p.stock }
            end

            # Adds a product to the shopping list
            def add_product(product)
              products << product
            end
          RUBY
        end
      end

      # Step 5: Add ActionText to Product for metadata
      def add_action_text_to_product
        inject_into_class "app/models/product.rb", "Product" do
          "  has_rich_text :metadata\n"
        end
      end
      
      #Step 6: Connect Shopping to Payment Processing
      def connect_shopping_to_payments
        generate "nevaeh:payment"
      end
      
      
    end
  end
end
