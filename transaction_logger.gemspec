# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'transaction_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "transaction_logger"
  spec.version       = TransactionLogger::VERSION
  spec.authors       = ["John Donner", "Sebastian Schleicher"]
  spec.email         = ["johnbdonner@gmail.com", "sebastian.julius@gmail.com"]
  spec.summary       = %q{Business Transactions Logger for Ruby}
  spec.description   = %q{Let's you make supercharged logging with hashes instead of single lines}
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
end
