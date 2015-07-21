require "spec_helper"
require "logger"

describe TransactionLogger do
  let (:test_lmbda) {
    lambda  do |_t|
    end
  }

  subject {
    TransactionLogger::Transaction.new(
      { prefix: nil, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
  }

  it "initializes with a nil parent" do
    expect(subject.parent).to be_nil
  end

  it "responds to .start" do
    expect(described_class).to receive(:start)
    described_class.start -> (_t) do end
  end

  context "when there is a parent" do
    let (:test_parent) { subject }
    let (:child) {
      TransactionLogger::Transaction.new(
        { parent: test_parent, prefix: nil, logger: Logger.new(STDOUT), level_threshold: nil }, test_lmbda)
    }
    let (:test_parent_log_queue) { test_parent.instance_variable_get(:@log_queue) }

    it "has a parent" do
      expect(child).to have_attributes(parent: test_parent)
    end

    it "places itself into the log of the parent" do
      expect(test_parent_log_queue).to include(child)
    end
  end

  describe ".start" do
    let (:test_lmbda) {
      described_class.start lambda (t) do
        t.log ""
      end
    }
  end

  describe TransactionLogger::Configure do
    describe ".log_prefix" do
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
