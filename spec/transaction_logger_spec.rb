require "spec_helper"
require "logger"

describe TransactionLogger do
  it "does something" do
    described_class.logger = Logger.new STDOUT
  end
end
