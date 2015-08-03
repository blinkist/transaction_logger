require "spec_helper"
require "logger"

describe TransactionLogger::Configure do
  let (:test_lmbda) {
    lambda do |_t|
    end
  }

  describe ".log_prefix" do
    subject {
      TransactionLogger::Transaction.new(
        { prefix: nil, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
    }

    context "when there is no prefix" do
      it "does not change the output" do
        expect(subject.to_hash).to include("name" => "undefined")
      end
    end

    context "when a prefix is defined" do
      let (:prefix) { "bta_" }

      before :example do
        described_class.log_prefix = prefix
      end

      subject {
        TransactionLogger::Transaction.new(
          { prefix: described_class.log_prefix, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
      }

      after :example do
        described_class.log_prefix = ""
      end

      it "adds the prefix to every key" do
        expect(subject.to_hash).to include("bta_name" => "undefined")
      end
    end
  end
end
