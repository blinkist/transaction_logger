require "spec_helper"
require "logger"

describe TransactionLogger::Transaction do
  let (:test_lmbda) {
    lambda do |_t|
    end
  }

  subject {
    TransactionLogger::Transaction.new(
      { prefix: nil, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
  }

  describe "#run" do
    context "when no exception is raised" do
      let (:test_lmbda) {
        lambda  do |_t|
          "result"
        end
      }

      let (:result) { subject.run }

      it "returns lmda" do
        expect(result).to eq "result"
      end
    end

    context "when an exception is raised" do
      let (:test_lmbda) {
        lambda  do |_t|
          fail "test error"
        end
      }

      let (:child) {
        TransactionLogger::Transaction.new(
          { prefix: nil, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
      }

      let (:result) { subject.run }

      it "raises an exception" do
        expect { result }.to raise_error "test error"
      end

      it "calls failure" do
        expect(subject).to receive(:failure)
        result
      end
    end
  end
end
