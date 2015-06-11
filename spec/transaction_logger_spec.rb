require "spec_helper"
require "logger"

describe TransactionLogger do

  let (:test_lmbda) {
    -> (t) do
    end
  }

  subject { TransactionLogger::Transaction.new nil, test_lmbda }

  it "initializes with a nil parent" do
    expect(subject.parent).to be_nil
  end

  it "responds to .start" do
    expect(described_class).to receive(:start)
    described_class.start -> (t) do end
  end

  context "when there is a parent" do

    let (:test_parent) { subject }
    let (:child) { child = TransactionLogger::Transaction.new test_parent, test_lmbda }
    let (:test_parent_log_queue) { test_parent.instance_variable_get(:@log_queue) }

    it "has a parent" do
      expect(child).to have_attributes(:parent => test_parent)
    end

    it "places itself into the log of the parent" do
      expect(test_parent_log_queue).to include(child)
    end

    context "when there is an error" do

      it "raises the error to the parent" do

      end

    end

  end

  context "when in 3-level nested transactions" do
    it "raises an error" do
      expect {
        described_class.start -> (t) do
          t.context = {user_id: 01, information: "contextual info"}
          t.log "First Message"

          described_class.start -> (t2) do
            t2.context = {user_id: 01, information: "contextual info"}
            t2.log "Second Message"
            t2.log "Third Message"

          end

          t.log "Fourth Message"

          described_class.start -> (t3) do
            t3.context = {user_id: 01, information: "contextual info"}
            t3.log "Fifth Message"

            described_class.start -> (t4) do
              t4.context = {user_id: 01, information: "contextual info"}
              t4.log "Sixth Message"
              t4.log "Seventh Message"

              fail RuntimeError, "test error"
            end

            t3.log "Eighth Message"
          end

        end
      }.to raise_error RuntimeError
    end
  end

  describe ".start" do
    let (:test_lmbda) {
      described_class.start -> (t) do
        t.log ""
      end
    }
  end

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

      after :example do
        described_class.log_prefix = ""
      end

      it "adds the prefix to every key" do
        expect(subject.to_hash).to include("bta_name" => "undefined")
      end
    end

  end

  describe "#run" do

    context "when no exception is raised" do

      let (:test_lmbda) {
        -> (t) do
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
        -> (t) do
          fail RuntimeError, "test error"
        end
      }

      let (:result) { subject.run }

      it "raises an exception" do
        expect{result}.to raise_error "test error"
      end

      it "calls failure" do
        expect(subject).to receive(:failure)
        result
      end

    end

  end

  # Try to think of ways to refactor this
  #   given that I can test certain specific behaviors
  #   first, and then use those tests to know the bigger
  #   picture is working...
  describe "Logger" do

    subject {
      Logger.new STDOUT
    }

    before :each do
      described_class.logger = subject
    end

    context "when there is one transaction" do

      it "recieves nothing" do
        expect(subject).to_not receive(:error)

        described_class.start -> (t) do
          t.context = {user_id: 01, information: "contextual info"}
          t.log "First Message"
        end
      end

      it "recieves error if an exception occurs" do
        expect(subject).to receive(:error)
        expect {
          described_class.start -> (t) do
            t.context = {user_id: 01, information: "contextual info"}
            t.log "First Message"
            fail RuntimeError, "test error"
          end
        }.to raise_error(RuntimeError)
      end

    end

    context "when there is a nested transaction with two levels" do

      it "recieves error if an exception occurs" do
        expect(subject).to receive(:error) do |options|
          expect(options["history"]).to include( {"info" => "First Message"} )
          expect(options["history"].last["history"]).to include({"info" => "Second Message"})
          expect(options["history"].last["history"].last["error_message"]).to eq("test error")
          expect(options["history"].last["history"].last["error_class"]).to eq("RuntimeError")
        end

        expect {
          described_class.start -> (t) do
            t.context = {user_id: 01, information: "contextual info"}
            t.log "First Message"
            described_class.start -> (t2) do
              t2.log "Second Message"
              fail RuntimeError, "test error"
            end
          end
        }.to raise_error RuntimeError
      end

    end

    context "when there are two nested transactions, two-levels deep" do

      it "recieves error if an exception occurs" do

        expect(subject).to receive("error") do |options|
          expect(options["history"].first["history"]).to include({"info" => "First Message"})
          expect(options["history"].last["history"]).to include({"info" => "Second Message"})
          expect(options["history"].last["history"].last["error_message"]).to eq("test error")
          expect(options["history"].last["history"].last["error_class"]).to eq("RuntimeError")
        end

        expect {
          described_class.start -> (t) do
            t.context = {user_id: 01, information: "contextual info"}
            described_class.start -> (t2) do
              t2.log "First Message"
            end
            described_class.start -> (t2) do
              t2.log "Second Message"
              fail RuntimeError, "test error"
            end
          end
        }.to raise_error RuntimeError
      end

    end

  end

end
