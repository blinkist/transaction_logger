# Blinkist TransactionLogger
[ ![Codeship Status for blinkist/transaction_logger](https://codeship.com/projects/fb9745c0-edc7-0132-b6b1-1efd3f886df2/status?branch=master)](https://codeship.com/projects/84119) [![Code Climate](https://codeclimate.com/github/blinkist/transaction_logger/badges/gpa.svg)](https://codeclimate.com/github/blinkist/transaction_logger)

Business Transactions Logger for Ruby

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

You may configure the logger by calling TransactionLogger.logger, such as with Ruby's Logger:

```ruby
logger = Logger.new STDOUT
TransactionLogger.logger = logger
```

Once you configure an appropriate logger, you may use the class anywhere to begin logging.

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
t.context = { specific: "context: #{value}" }
t.log "A message you want logged"
```

## Contributing

1. Fork it ( https://github.com/blinkist/transaction_logger/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
