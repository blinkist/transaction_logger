# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'transaction_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "transaction_logger"
  spec.version       = TransactionLogger::VERSION
  spec.authors       = ["John Donner", "Sebastian Schleicher"]
  spec.email         = ["johnbdonner@gmail.com", "sebastian.julius@gmail.com"]
  spec.summary       = 'Contextual Business Transaction Logger for Ruby'
  spec.description   = 'A logger that silently collects information in the
                          background and when an error is raised, logs a hash either
                          out to the System or pushes the log to a service such as
                          Loggly. The log hash contains information such as the
                          backtrace, any logs from calling classes and methods,
                          and configurable contextual information.'
  spec.homepage      = "https://github.com/blinkist/transaction_logger"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new ">= 2.1.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "github-markdown"
  spec.add_development_dependency "rubocop"
end
