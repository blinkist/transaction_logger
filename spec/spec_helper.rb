$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "transaction_logger"

require "support/debugging"

RSpec.configure do |config|
  config.order = "random"

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate
end
