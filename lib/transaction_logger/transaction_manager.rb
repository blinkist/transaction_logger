require "logger"
require "transaction_logger/version"
require "transaction_logger/transaction"

class TransactionLogger::TransactionManager

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
  # @param lmbda [Proc]
  #
  def self.start(lmbda)

    active_transaction = get_active_transaction

    transaction = TransactionLogger::Transaction.new active_transaction, lmbda
    active_transaction = transaction

    set_active_transaction active_transaction

    begin
      transaction.run
    rescue Exception => e
      raise e
    ensure
      set_active_transaction transaction.parent
    end
  end

  # Sets the TransactionLogger's output to a specific instance of Logger.
  #
  # @param logger [Logger] Any instace of ruby Logger
  #
  def self.logger=(logger)
    @@logger = logger
  end

  # Sets the TransactionLogger's output to a new instance of Logger
  #
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  # Sets the hash keys on the TransactionLogger's log to have a prefix.
  #
  # Using .log_prefix "str_", the output of the log hash will contain keys prefixed
  # with "str_", such as { "str_name" => "Class.method" }.
  #
  # @param prefix [#to_s] Any String or Object that responds to to_s
  #
  def self.log_prefix=(prefix)
    @@prefix = "#{prefix}"
  end

  # @private
  # Returns the log_prefix
  #
  # @return [String] The currently stored prefix.
  #
  def self.log_prefix
    @@prefix
  end

  # @private
  # Returns the current parent of a thread of Transactions.
  #
  # @return [TransactionLogger::Transaction] The current parent given a Thread
  #
  def self.get_active_transaction
    if @@current_transactions.has_key?(Thread.current.object_id)
      @@current_transactions[Thread.current.object_id]
    end
  end

  # @private
  # Sets the current parent of a thread of Transactions.
  #
  def self.set_active_transaction(transaction)
    @@current_transactions[Thread.current.object_id] = transaction
  end

end
