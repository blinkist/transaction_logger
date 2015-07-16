require "logger"
require "transaction_logger/version"
require "transaction_logger/transaction"

module TransactionLogger
  class TransactionManager

    @@prefix = ""
    @@current_transactions = {}

    # Marks the beginning of a "Transaction lambda," which will log an error if the
    #   containing code raises an error. A lambda instance variable let's you call
    #   the .log method and access the ".name" and ".context" variables. The start
    #   method must take a lambda as an argument.
    #
    #   Whatever the outer method is, if a value is returned within the Transaction
    #   lambda it will be returned to the outer method as well.
    #
    #   The start method does not catch errors, so if an error is raised, it will simply
    #   envoke a logging message to be outputted and then raise the error.
    #
    #   This also checks which thread is envoking the method in order to make sure the
    #   logs are thread-safe.
    #
    # @param prefix [String]
    # @param logger [Logger]
    # @param level_threshold [Symbol]
    # @param lmbda [Proc]
    #
    def self.start(options={}, lmbda)
      options[:parent] = active_transaction

      transaction = TransactionLogger::Transaction.new options, lmbda
      self.active_transaction = transaction

      begin
        transaction.run
      rescue StandardError => e
        raise e
      ensure
        self.active_transaction = transaction.parent
      end
    end

    # @private
    # Returns the current parent of a thread of Transactions.
    #
    # @return [TransactionLogger::Transaction] The current parent given a Thread
    #
    def self.active_transaction
      if @@current_transactions.key?(Thread.current.object_id)
        @@current_transactions[Thread.current.object_id]
      end
    end

    # @private
    # Sets the current parent of a thread of Transactions.
    #
    def self.active_transaction=(transaction)
      @@current_transactions[Thread.current.object_id] = transaction
    end

  end
end
