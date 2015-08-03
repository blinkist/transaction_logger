# Blinkist TransactionLogger
[ ![Codeship Status for blinkist/transaction_logger](https://codeship.com/projects/fb9745c0-edc7-0132-b6b1-1efd3f886df2/status?branch=master)](https://codeship.com/projects/84119) [![Gem Version](https://badge.fury.io/rb/transaction_logger.svg)](http://badge.fury.io/rb/transaction_logger) [![Code Climate](https://codeclimate.com/github/blinkist/transaction_logger/badges/gpa.svg)](https://codeclimate.com/github/blinkist/transaction_logger) [![Dependency Status](https://www.versioneye.com/ruby/transaction_logger/badge.svg)](https://www.versioneye.com/ruby/transaction_logger/)

Business Transactions Logger for Ruby that compiles contextual logging information and can send it to a configured logging service such as Logger or Loggly in a nested hash.

## Table of Contents

1. [Installation](#installation)
2. [Output](#output)
3. [Configuration](#configuration)
4. [Usage](#usage)
5. [Version History](#version-history)
6. [Contributing](#contributing)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "transaction_logger"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install transaction_logger

## Output

By registering a method with TransactionLogger, the TransactionLogger is expected to print out every log that occurred under this method, and each nested method's local information as well.

When a transaction raises an error, it will log the *error message*, *error class*, and *10 lines* of the backtrace by default. This will be logged at the level of the transaction that raised the error.

Additionally, if no errors are raised, but an *error* or *fatal* log is made, then the TransactionLogger will send it's log hash to the configured logger.

## Configuration

Configure the logger by calling TransactionLogger.logger, such as with Ruby's Logger:

```ruby
logger = Logger.new STDOUT # Ruby default logger setup
TransactionLogger::Configure.logger = logger
```

Calling Transaction_Logger.logger with no parameter sets the logger to a new instance of Logger as shown above.

### Configuring the Prefix

You can add a prefix to every hash key in the log by using the class method log_prefix:

```ruby
TransactionLogger::Configure.log_prefix = "transaction_logger_"
# output hash:
# {
#   "transaction_logger_name" => "some name"
#   "transaction_logger_context" => { "user_id" => 1 }
#   ...
# }
```

### Configuring the Log Level Threshold

You may also choose at which log level the TransactionLogger sends it's log hash. By default, *error* is the threshold, so that if an *error* or *fatal* log is made, then the TransactionLogger will send a JSON hash to it's configured logger. If you wish to set the threshold to *warn*, you can configure the TransactionLogger to do so:

```ruby
TransactionLogger::Configure.level_threshold = :warn
```

## Usage

To register a method as a transaction, include the TransactionLogger and use *add_transaction_log* after the method definition:

```ruby
class YourClass
  include TransactionLogger

  def some_method
    logger.info "logged message"
    # method code
  end

  add_transaction_log :some_method
end
```

By default, the transaction will be named *YourClass:some_method*. You can easily change this by adding the name to the options params:

```ruby
add_transaction_log :some_method, {name: "Custom Name" }
```

You can set a *context* to the options that is pushed to the logger. It can either anything supporting `.to_hash` or a `Proc`.
The proc will be evaluated in the scope of the traced method.

```ruby
add_transaction_log :some_method, {context: "Custom Context" }
add_transaction_log :some_method, {context: { key: "value context" } }
add_transaction_log :some_method, {context: -> { request.params } }
```

### Example

Assuming there is already an instance of Ruby's Logger class, here is a transaction that raises an error:

```ruby
class ExampleClass
  def some_method(result)
    include TransactionLogger

    logger.info "Trying something complex"
    raise RuntimeError, "Error"

    result
    logger.info "Success"
  end

  add_transaction_log :some_method, { context: { some_id: 12 } }
end
```

The expected output is:

```json
{
  "name": "ExampleClass:some_method",
  "context": {
    "some_id": 12
  },
  "duration": 0.112,
  "history": [{
    "info": "Trying something complex"
    }, {
      "error_message": "Error",
      "error_class": "RuntimeError",
      "error_backtrace": [
        "example_class.rb:6:in `some_method'",
        ".../transaction_logger.rb:86:in `call'",
        ".../transaction_logger.rb:86:in `block (2 levels) in add_transaction_log'",
        ".../transaction_logger/transaction.rb:37:in `call'",
        ".../transaction_logger/transaction.rb:37:in `run'",
        ".../transaction_logger/transaction_manager.rb:41:in `start'",
        ".../transaction_logger.rb:78:in `block in add_transaction_log'",
        "test.rb:4:in `<main>'"
      ]

  }]
}
```

## Version History

### v1.1.0
- Fixed issues #32 for missing context
- Added support for Proc as context #34

### v1.0.1
- Fixed issues with undefined trap_logger method
- Hid module methods other than add_transaction_log
- TransactionLogger configuration updated

### v1.0.0

- AOP approach that provides a much cleaner, easier implementation of the TransactionLogger
- Added default transaction name
- Added support for log level threshold

### v0.1.0

- Added support for log prefixes

### v0.0.1

- initial version

## Contributing

1. Fork it ( https://github.com/blinkist/transaction_logger/fork )
2. Create your feature branch (`git checkout -b feature/your_feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/your_feature`)
5. Create a new Pull Request
