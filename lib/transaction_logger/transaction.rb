class TransactionLogger::Transaction
  attr_reader :parent

  attr_accessor :name
  attr_accessor :context

  # @param parent [TransactionLogger::Transaction]
  #
  def initialize(parent=nil)
    @parent = parent
    @parent.log self if @parent

    @name = "undefined"
    @context = {}
    @log_queue = Array.new
    @start = Time.now
    @error_printed = nil
  end

  # Runs the lines of code from within the lambda.
  #
  # @param lmbda [Proc]
  #
  # @return [something] the calling method's return
  #
  def run(lmbda)
    begin
      result = lmbda.call self
    rescue => error

      log({
        transaction_error_message: error.message,
        transaction_error_class: error.class.name,
        transaction_error_backtrace: error.backtrace.take(5)
      })

      failure error, self
    else
      success self
    end

    result
  end

  # Calculates the duration upon the success of a transaction
  #
  # @param transaction [TransactionLogger::Transaction]
  #
  def success(transaction)
    calc_duration
  end

  # Logs the error and raises error to the parent process
  #
  # @param error [Exception]
  # @param transaction [TransactionLogger:Transaction]
  #
  # @raise [Exception]
  #
  def failure(error, transaction)
    calc_duration

    if @parent
      @parent.failure error, transaction
    else
      unless @error_printed
        print_transactions
        @error_printed = true
      end

      raise error
    end
  end

  # Pushes a message into the log queue
  #
  # @param message [String] Typically a String
  #
  def log(message)
    if message.is_a? String
      message = { transaction_info: message }
      @log_queue.push message
    else
      @log_queue.push message
    end
  end

  # Calculates the number of milliseconds that the Transaction has taken
  #
  def calc_duration
    @duration = (Time.now - @start) * 1000.0
  end

  # Sends the transaction context and log to an instance of logger
  #
  # @param transaction [TransactionLogger::Transaction]
  #
  def print_transactions(transaction=nil)
    TransactionLogger.logger.error to_hash
  end

  # Converts a Transaction and it's children into a single nested hash
  #
  # @return [Hash] the log, error and contextual information
  #
  def to_hash
    output = {
      transaction_name: @name,
      transaction_context: @context,
      transaction_duration: @duration,
      transaction_history: []
    }

    @log_queue.each {|entry|
      if entry.is_a? TransactionLogger::Transaction
        output[:transaction_history] << entry.to_hash
      elsif entry.is_a? Hash
        output[:transaction_history] << entry
      else
        output[:transaction_history] << entry
      end
    }

    output
  end

end
