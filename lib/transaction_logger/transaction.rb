require "json"
require "logger"

class TransactionLogger::Transaction
  attr_reader :parent

  attr_accessor :name
  attr_accessor :context
  attr_accessor :level_threshold
  attr_accessor :level_threshold_broken

  # @param parent [TransactionLogger::Transaction] Parent of transaction
  # @param lmbda [Proc] The surrounded block
  #
  def initialize(parent=nil, log_prefix, logger, level_threshold, lmbda)
    @parent = parent
    @parent.log self if @parent

    @lmbda = lmbda

    @log_prefix = log_prefix
    @name = "undefined"
    @context = {}
    @level_threshold = level_threshold || :error
    @log_queue = Array.new
    @start = Time.now
    @error_printed = nil
    @level_threshold_broken = false

    @logger = logger
  end

  # @private
  # Runs the lines of code from within the lambda. FOR INTERNAL USE ONLY.
  #
  def run
    begin
      result = @lmbda.call self
    rescue => error

      e_message_key = "#{@log_prefix}error_message"
      e_class_key = "#{@log_prefix}error_class"
      e_backtrace_key = "#{@log_prefix}error_backtrace"

      log({
        e_message_key => error.message,
        e_class_key => error.class.name,
        e_backtrace_key => error.backtrace.take(10)
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
  def log(message, level=:info)
    check_level(level)
    if message.is_a? String
      message_key = "#{@log_prefix}#{level}"
      message = { message_key => message }
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
    name_key = "#{@log_prefix}name"
    context_key = "#{@log_prefix}context"
    duration_key = "#{@log_prefix}duration"
    history_key = "#{@log_prefix}history"

    output = {
      name_key => @name,
      context_key => @context,
      duration_key => @duration,
      history_key => []
    }

    @log_queue.each {|entry|
      if entry.is_a? self.class
        output[history_key] << entry.to_hash
      elsif entry.is_a? Hash
        output[history_key] << entry
      else
        output[history_key] << entry
      end
    }

    output
  end

  # @private
  #
  def check_level(level)
    levels = { debug: 0, info: 1, warn: 2, error: 3, fatal: 4}
    input_level_id = levels[level]
    level_threshold_id = levels[@level_threshold]
    if level_threshold_id
      @level_threshold_broken = true if input_level_id >= level_threshold_id
    else
      @level_threshold_broken = true if input_level_id >= 3
    end
  end


  private

  # Calculates the duration upon the success of a transaction
  def success
    calc_duration

    unless @error_printed || !@level_threshold_broken
      if @parent
        @parent.instance_variable_set :@level_threshold_broken, true
      else
        print_transactions
        @error_printed = true
      end
    end

    #unless @parent || @error_printed || !@level_threshold_broken
    #end
  end

  # Calculates the number of milliseconds that the Transaction has taken
  def calc_duration
    @duration = (Time.now - @start) * 1000.0
  end

  # Sends the transaction context and log to an instance of logger
  def print_transactions
    @logger ||= Logger.new(STDOUT)
    @logger.error to_hash
  end

end
