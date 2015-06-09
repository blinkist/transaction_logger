
class TransactionLogger::Transaction
  attr_reader :parent

  attr_accessor :name
  attr_accessor :context

  # @param parent [TransactionLogger::Transaction] Parent of transaction
  # @param lmbda [Proc] The surrounded block
  #
  def initialize(parent=nil, lmbda)
    @parent = parent
    @parent.log self if @parent

    @lmbda = lmbda

    @name = "undefined"
    @context = {}
    @log_queue = Array.new
    @start = Time.now
    @error_printed = nil
  end

  # @private
  # Runs the lines of code from within the lambda. FOR INTERNAL USE ONLY.
  #
  def run
    begin
      result = @lmbda.call self
    rescue => error

      log({
        transaction_error_message: error.message,
        transaction_error_class: error.class.name,
        transaction_error_backtrace: error.backtrace.take(5)
      })

      failure error, self
    else
      success
    end

    result
  end

  # Pushes a message into the log queue. Logs are stored in order
  #   of time logged. Note that this method will not output a log, but just
  #   stores it in the queue to be outputted if an error is raised in a
  #   transaction.
  #
  # @param message [#to_s] Any String or Object that responds to to_s
  #   that you want to be stored in the log queue.
  #
  def log(message)
    if message.is_a? String
      message = { transaction_info: message }
      @log_queue.push message
    else
      @log_queue.push message
    end
  end

  # @private
  # Logs the error and raises error to the parent process
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

  # @private
  # Converts a Transaction and it's children into a single nested hash
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


  private

  # Calculates the duration upon the success of a transaction
  def success
    calc_duration
  end

  # Calculates the number of milliseconds that the Transaction has taken
  def calc_duration
    @duration = (Time.now - @start) * 1000.0
  end

  # Sends the transaction context and log to an instance of logger
  def print_transactions(transaction=nil)
    TransactionLogger.logger.error to_hash
  end

end
