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

The expected output is:

```json
{
    "transaction_name": "undefined",
    "transaction_context": {},
    "transaction_duration": 0.081,
    "transaction_history": [{
        "transaction_error_message": "test error",
        "transaction_error_class": "RuntimeError",
        "transaction_error_backtrace": [
            "/Users/jdonner94/Documents/CODING/blinkist/transaction_logger/spec/transaction_logger_spec.rb:108:in `block (5 levels) in <top (required)>'",
            "/Users/jdonner94/Documents/CODING/blinkist/transaction_logger/lib/transaction_logger/transaction.rb:22:in `call'",
            "/Users/jdonner94/Documents/CODING/blinkist/transaction_logger/lib/transaction_logger/transaction.rb:22:in `run'",
            "/Users/jdonner94/Documents/CODING/blinkist/transaction_logger/spec/transaction_logger_spec.rb:112:in `block (4 levels) in <top (required)>'",
            "/Users/jdonner94/.rvm/rubies/ruby-2.1.2/lib/ruby/gems/2.1.0/gems/rspec-core-3.2.3/lib/rspec/core/memoized_helpers.rb:242:in `block (2 levels) in let'"
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
