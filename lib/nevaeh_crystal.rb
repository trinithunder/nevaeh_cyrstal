# frozen_string_literal: true

# Only require Railtie if running inside a Rails app
require 'nevaeh/railtie' if defined?(Rails)

# Auto-load all generators inside `lib/nevaeh/generators/`
Dir[File.join(__dir__, 'nevaeh', 'generators', '*.rb')].sort.each { |file| require file }

require_relative "nevaeh_crystal/version"

module NevaehCrystal
  class Error < StandardError; end
end
