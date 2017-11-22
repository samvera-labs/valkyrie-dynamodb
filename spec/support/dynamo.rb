# frozen_string_literal: true
RSpec.configure do |config|
  config.before do
    Valkyrie::Persistence::DynamoDB::MetadataAdapter.new(
      connection: dynamodb_client
    ).persister.wipe!
  end
end

def dynamodb_client
  options = ENV['TEST_ON_AWS'] ? {} : { endpoint: 'http://localhost:8000' }
  Aws::DynamoDB::Client.new(options)
end
