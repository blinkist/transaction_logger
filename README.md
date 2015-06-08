# Blinkist TransactionLogger
[ ![Codeship Status for blinkist/transaction_logger](https://codeship.com/projects/fb9745c0-edc7-0132-b6b1-1efd3f886df2/status?branch=master)](https://codeship.com/projects/84119) [![Code Climate](https://codeclimate.com/github/blinkist/transaction_logger/badges/gpa.svg)](https://codeclimate.com/github/blinkist/transaction_logger)

Business Transactions Logger for Ruby that compiles contextual logging information and can send it to a configured logging service such as Logger or Loggly in a nested hash.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transaction_logger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install transaction_logger

## Output

Given a root transaction, the TransactionLogger is expected to print out every log that occurred under this root transaction, and each sub-transaction's local information.

When a transaction raises an error, it will log the *error message*, *error class*, and *10 lines* of the backtrace by default. This will be logged at the level of the transaction that raised the error.

## Usage

Configure the logger by calling TransactionLogger.logger, such as with Ruby's Logger:

```ruby
logger = Logger.new STDOUT
TransactionLogger.logger = logger
```

Wrap a business transaction method with a TransactionLogger lambda:

```ruby
def some_method
  TransactionLogger.start -> (t) do
    # your code.
  end
end
```

From within this lambda, you may call upon t to add a custom name, context and log your messages, like so:

```ruby
t.name = "YourClass.some_method"
t.context = { specific: "context: #{value}" }
t.log "A message you want logged"
```

### Example

Here is a transaction that raises an error:

```ruby
class ExampleClass
  def some_method
    TransactionLogger.start -> (t) do
      t.name = "ExampleClass.some_method"
      t.context = { some_id: 12 }

      t.log "Trying something complex"
      raise RuntimeError, "Error"

      result
      t.log "Success"
    end
  end
end
```

The expected output is:

```json
{
  "transaction_name": "ExampleClass.some_method",
  "transaction_context": {
    "some_id": 12
  },
  "transaction_duration": 0.112,
  "transaction_history": [{
    "transaction_info": "Trying something complex"
    }, {
      "transaction_error_message": "Error",
      "transaction_error_class": "RuntimeError",
      "transaction_error_backtrace": [
        "example.rb:84:in `block in nested_method'",
        ".../TransactionLogger_Example/transaction_logger.rb:26:in `call'",
        ".../TransactionLogger_Example/transaction_logger.rb:26:in `run'",
        ".../TransactionLogger_Example/transaction_logger.rb:111:in `start'",
        "example.rb:79:in `nested_method'"
      ]

  }]
}
```

## Contributing

1. Fork it ( https://github.com/blinkist/transaction_logger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
