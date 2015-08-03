require "transaction_logger/version"
require "transaction_logger/transaction"
require "transaction_logger/transaction_manager"

module TransactionLogger

  # @private
  # Includes ClassMethods of including class to the TransactionLogger
  #
  def self.included(base)
    base.extend ClassMethods
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

      options[:prefix] = TransactionLogger::Configure.instance_variable_get :@prefix
      options[:logger] = TransactionLogger::Configure.instance_variable_get :@logger
      options[:level_threshold] = TransactionLogger::Configure.instance_variable_get :@level_threshold

      define_method method do
        context = options[:context]

        if context.is_a? Proc
          begin
            context = instance_exec(&context)
          rescue => e
            context = "TransactionLogger: couldn't evaluate context: #{e.message}"
            # Write an error to the untrapped logger
            logger.error context
            logger.error e.backtrace.take(10).join "\n"
          end
        end

        TransactionManager.start options, lambda  { |transaction|
          transaction.name = options[:name]
          transaction.name ||= "#{old_method.bind(self).owner}#{method.inspect}"
          transaction.context = context || {}

          # Check for a logger on the instance
          if methods.include? :logger
            logger_method = method(:logger).unbind
          # Check for a logger on the class
          elsif self.class.methods.include? :logger
            logger_method = self.class.method :logger
          end

          # Trap the logger if we've found one
          if logger_method
            method_info = {}
            method_info[:logger_method] = logger_method
            method_info[:calling_method] = caller_locations(1, 1)[0].label
            method_info[:includer] = self

            TransactionLogger::Helper.trap_logger method, transaction, method_info
          end

          old_method.bind(self).call
        }
      end
    end

  end

  class Helper
    # @private
    # Traps the original logger inside the TransactionLogger
    #
    # @param method [Symbol]
    # @param transaction [Transaction]
    #
    def self.trap_logger(_method, transaction, method_info={})
      logger_method = method_info[:logger_method]
      calling_method = method_info[:calling_method]
      includer = method_info[:includer]

      if logger_method.is_a? UnboundMethod
        method_type = :define_method
      else
        method_type = :define_singleton_method
      end

      includer.class.send method_type, :logger, lambda {
        if logger_method.is_a? UnboundMethod
          @original_logger ||= logger_method.bind(includer).call
        else
          @original_logger ||= logger_method.call
        end

        @trapped_logger ||= {}
        @trapped_logger[calling_method] ||= LoggerProxy.new @original_logger, transaction
      }
    end

  end

  class Configure
    # Sets the hash keys on the TransactionLogger's log to have a prefix.
    #
    # Using .log_prefix "str_", the output of the log hash will contain keys
    # prefixed with "str_", such as { "str_name" => "Class.method" }.
    #
    # @param prefix [#to_s] Any String or Object that responds to to_s
    #
    def self.log_prefix=(prefix)
      @prefix = prefix
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
    class << self
      attr_writer :logger
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
    class << self
      attr_writer :level_threshold
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
        @transaction.log(*args, level)
      end
    end

    # @private
    def method_missing(method, *args)
      @original_logger.send method, *args
    end
  end
end
