require "transaction_logger/version"
require "transaction_logger/transaction"

class TransactionLogger

  @@current_transactions = {}

  # Starts Transaction and runs new instance
  #
  # @param lmbda [Proc]
  # 
  def self.start(lmbda)

    active_transaction = get_active_transaction

    transaction = TransactionLogger::Transaction.new active_transaction
    active_transaction = transaction

    set_active_transaction active_transaction

    begin
      transaction.run lmbda
    rescue Exception => e
      raise e
    ensure
      set_active_transaction transaction.parent
    end
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.get_active_transaction
    if @@current_transactions.has_key?(Thread.current.object_id)
      @@current_transactions[Thread.current.object_id]
    end
  end

  def self.set_active_transaction(transaction)
    @@current_transactions[Thread.current.object_id] = transaction
  end

end
