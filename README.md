# Valkyrie::DynamoDB

An [AWS DynamoDB](https://aws.amazon.com/dynamodb/) metadata backend for [Valkyrie](https://github.com/samvera-labs/valkyrie)

[![CircleCI](https://circleci.com/gh/samvera-labs/valkyrie-dynamodb.svg?style=svg)](https://circleci.com/gh/samvera-labs/valkyrie-dynamodb)
[![Coverage Status](https://coveralls.io/repos/github/samvera-labs/valkyrie-dynamodb/badge.svg?branch=master)](https://coveralls.io/github/samvera-labs/valkyrie-dynamodb?branch=master)

## Requirements

### Ruby version
Ruby 2.3 or above

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'valkyrie-dynamodb'
```

## Usage

Follow the Valkyrie README to get a development or production environment up and running. To enable DynamoDB support,
add the following to your application's `config/initializers/valkyrie.rb`:

    Valkyrie::MetadataAdapter.register(
      Valkyrie::Persistence::DynamoDB::MetadataAdapter.new,
      :dynamodb
    )

You can then use `:dynamodb` as a metadata adapter value in `config/valkyrie.yml`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samvera-labs/valkyrie-dynamodb/.

## License

`Valkyrie::DynamoDB` is available under [the Apache 2.0 license](LICENSE).
