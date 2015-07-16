require "transaction_logger/version"
require "transaction_logger/transaction"
require "transaction_logger/transaction_manager"

module TransactionLogger

  # @private
  # Extends ClassMethods of including class to the TransactionLogger
  #
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Sets the hash keys on the TransactionLogger's log to have a prefix.
  #
  # Using .log_prefix "str_", the output of the log hash will contain keys
  # prefixed with "str_", such as { "str_name" => "Class.method" }.
  #
  # @param prefix [#to_s] Any String or Object that responds to to_s
  #
  def self.log_prefix=(prefix)
    @prefix = "#{prefix}"
  end

  # @private
  # Returns the log_prefix
  #
  # @return [String] The currently stored prefix.
  #
  def self.log_prefix
    @prefix
  end

  # Sets the TransactionLogger's output to a specific instance of Logger.
  #
  # @param logger [Logger] Any instace of ruby Logger
  #
  def self.logger=(logger)
    @logger = logger
  end

  # Sets the TransactionLogger's output to a new instance of Logger
  #
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  # Sets the TransactionLogger's logger level threshold.
  #
  # @param level [Symbol] A symbol recognized by logger, such as :warn
  #
  def self.level_threshold=(level)
    @level_threshold = level
  end

  module ClassMethods

    # Registers a method with the TransactionLogger, which will begin tracking the
    #   logging within the method and it's nested methods. These logs are collected
    #   under one transaction, and if the level threshold is broken or when an error
    #   is raised, the collected logs are pushed to the configured logger as a JSON
    #   hash.
    #
    #   By registering multiple methods as transactions, each method becomes it's
    #   own transaction.
    #
    # @param method [Symbol] The method you want to register with TransactionLogger
    # @param options [Hash] Additional options, such as custom transaction name and context
    #
    def add_transaction_log(method, options={})
      old_method = instance_method method

      prefix = Module.nesting.last.instance_variable_get :@prefix
      logger = Module.nesting.last.instance_variable_get :@logger
      level_threshold = Module.nesting.last.instance_variable_get :@level_threshold

      define_method method do
        TransactionManager.start prefix, logger, level_threshold, -> (transaction) {

          transaction.name = options[:name]
          transaction.name ||= "#{old_method.bind(self).owner}#{method.inspect}"
          transaction.context = options[:context]
          transaction.context ||= {}

          self.class.trap_logger method, transaction
          old_method.bind(self).call
        }
      end
    end

    # @private
    # Traps the original logger inside the TransactionLogger
    #
    # @param method [Symbol]
    # @param transaction [Transaction]
    #
    def trap_logger(method, transaction)
      logger_method = instance_method :logger

      define_method :logger do
        @original_logger ||= logger_method.bind(self).call
        calling_method = caller_locations(1,1)[0].label

        @trapped_logger ||= {}
        @trapped_logger[calling_method] ||= LoggerProxy.new @original_logger, transaction
      end
    end
  end

  class LoggerProxy

    # @private
    def initialize(original_logger, transaction)
      @original_logger = original_logger
      @transaction = transaction
    end

    levels = %i( debug info warn error fatal )

    levels.each do |level|
      define_method level do |*args|
        @original_logger.send level, *args
        @transaction.log *args, level
      end
    end

    # @private
    def method_missing(method, *args)
      @original_logger.send method, *args
    end
  end
end
