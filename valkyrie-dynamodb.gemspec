# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "valkyrie/dynamodb/version"

Gem::Specification.new do |spec|
  spec.name          = "valkyrie-dynamodb"
  spec.version       = Valkyrie::DynamoDB::VERSION
  spec.authors       = ["Michael B. Klein"]
  spec.email         = ["mbklein@gmail.com"]

  spec.summary       = "AWS DynamoDB backend for Valkyrie"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'valkyrie'
  spec.add_dependency 'aws-sdk-dynamodb'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "bixby"
  spec.add_development_dependency 'rubocop', '~> 0.48.0'
  spec.add_development_dependency 'docker-stack', '~> 0.2.6'
end
