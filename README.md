# TransactionLogger

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
logger = LogglyLogger.new
TransactionLogger.logger = logger
```

Once you configure an appropriate logger, you may use the class anywhere to begin logging.

Wrap a business transaction method with a TransactionLogger lamnda.

Your method:

```ruby
def some_method
  # your code
end
```

Your method wrapped with a TransactionLogger lamnda

```ruby
def some_method
  TransactionLogger.start -> (t) do
    # your code.
  end
end
```

From within this lamnda, you may call upon t to add a custom name, context and log your messages, like so:

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
