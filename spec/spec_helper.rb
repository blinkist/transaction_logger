$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "transaction_logger"

require "support/debugging"

RSpec.configure do |config|
  config.order = "random"
end
