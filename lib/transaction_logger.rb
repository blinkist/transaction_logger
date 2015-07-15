require "transaction_logger/version"
require "transaction_logger/transaction"
require "transaction_logger/transaction_manager"

module TransactionLogger
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def add_transaction_log(method, options={})
      old_method = instance_method method

      define_method method do
        TransactionManager.start -> (transaction) {

          transaction.name = options[:name]
          transaction.name ||= "#{old_method.bind(self).owner}#{method.inspect}"
          transaction.context = options[:context]
          transaction.context ||= {}

          self.class.trap_logger method, transaction
          old_method.bind(self).call
        }
      end
    end

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
    def initialize(original_logger, transaction)
      @original_logger = original_logger
      @transaction = transaction
    end

    %i( debug info warn error fatal ).each do |level|
      define_method level do |*args|
        @original_logger.send level, *args
        @transaction.log *args
      end
    end

    def method_missing(method, *args)
      @original_logger.send method, *args
    end
  end
end
