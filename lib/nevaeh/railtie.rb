# lib/nevaeh/railtie.rb
require 'rails/railtie'

module Nevaeh
  class Railtie < Rails::Railtie
    # This ensures your generators are loaded when Rails runs generators
    generators do
      Dir[File.join(__dir__, 'generators', '*.rb')].each { |file| require file }
    end
  end
end
