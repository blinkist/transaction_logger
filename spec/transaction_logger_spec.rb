require "spec_helper"
require "logger"

describe TransactionLogger do
  let (:test_lmbda) {
    lambda do |_t|
    end
  }

  context "Logger trapping" do
    let(:instance_logger) {
      Class.new do
        include TransactionLogger

        def do_something(var)
          logger.info var
        end

        def logger
          Logger.new STDOUT
        end

        add_transaction_log :do_something
      end
    }

    let(:klass_logger) {
      Class.new do
        include TransactionLogger

        def do_something(var)
          self.class.logger.info var
        end

        def self.logger
          Logger.new STDOUT
        end

        add_transaction_log :do_something
      end
    }

    let(:no_logger) {
      Class.new do
        include TransactionLogger

        def do_something(var)
          puts var
        end

        add_transaction_log :do_something
      end
    }

    it "supports #logger" do
      expect_any_instance_of(TransactionLogger::LoggerProxy).to receive(:info).and_call_original
      expect_any_instance_of(Logger).to receive(:info).and_call_original
      test = instance_logger.new
      test.do_something "value"
    end

    it "supports .logger" do
      expect_any_instance_of(TransactionLogger::LoggerProxy).to receive(:info).and_call_original
      expect_any_instance_of(Logger).to receive(:info).and_call_original
      test = klass_logger.new
      test.do_something "value"
    end

    it "supports no logger" do
      expect_any_instance_of(TransactionLogger::LoggerProxy).to_not receive(:info)
      expect_any_instance_of(Logger).to_not receive(:info)
      test = no_logger.new
      test.do_something "value"
    end
  end

  context "logging options" do
    let(:logger_stub) { double(Logger) }

    let(:test_logger) {
      Class.new do
        include TransactionLogger

        def do_something
          raise "Error"
        end

        def logger
          Logger.new STDOUT
        end

        add_transaction_log :do_something, name: "my name", context: "my context"
      end
    }

    it "sets transaction name and context" do
      TransactionLogger::Configure.logger = logger_stub

      expect(logger_stub).to receive(:error) do |msg|
        expect(msg["context"]).to eq "my context"
        expect(msg["name"]).to eq "my name"
      end

      test = test_logger.new
      expect { test.do_something }.to raise_error "Error"
    end
  end

  context "Dynamic context" do
    let(:instance_logger_lambda) {
      Class.new do
        include TransactionLogger

        def do_something
          logger.info "TEST"
        end

        def dynamic_context
          "Dynamic Context"
        end

        def logger
          Logger.new STDOUT
        end

        add_transaction_log :do_something, context: -> { dynamic_context }
      end
    }

    it "executes the lambda bound to the logged instance" do
      test = instance_logger_lambda.new
      expect(test).to receive(:dynamic_context).and_call_original
      test.do_something
    end

    it "doesn't fail the method execution if the lambda eval fails" do
      test = instance_logger_lambda.new
      allow(test).to receive(:dynamic_context).and_raise "Some error"
      expect { test.do_something }.to_not raise_error
    end
  end

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
end
