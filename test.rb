require "./lib/transaction_logger.rb"
require "logger"

class TestClass
  include TransactionLogger

  def run
    logger.info "Starting to call a method"
    puts "method"

    logger.info "Calling the next method"
    puts "Entering nesting"

    another_try

    logger.info "Done"

    raise "Dummy"
  end

  def another_try
    puts "nested method call starts"
    logger.warn "Having a nested method call"

    sub = SubTestClass.new
    sub.test

    puts "nested done"
    logger.info "Awesome posome"
  end

  def logger
    @logger ||= Logger.new STDOUT
  end

  add_transaction_log :run
  add_transaction_log :another_try
end

class SubTestClass
  include TransactionLogger

  def test
    logger.info "This shouldn't be in the logs"
    puts "TEST TEST"

    raise "WOOP WOOP"
  end

  def logger
    @logger ||= Logger.new STDOUT
  end

  #add_transaction_log :test
end

t = TestClass.new
t.run
