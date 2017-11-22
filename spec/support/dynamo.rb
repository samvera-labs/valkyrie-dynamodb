# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:suite) do
    ignore_resource_error { dynamodb_client.delete_table(table_name: 'valkyrie_orm') }
    ignore_resource_error { dynamodb_client.delete_table(table_name: 'valkyrie_orm.refs') }
  end

  config.before do
    Valkyrie::Persistence::DynamoDB::MetadataAdapter.new(
      connection: dynamodb_client
    ).persister.wipe!
  end
end

def ignore_resource_error
  yield
rescue Aws::DynamoDB::Errors::ResourceNotFoundException
end

def dynamodb_client
  options = { endpoint: (ENV['DYNAMODB_ENDPOINT'] || 'http://localhost:8000') }
  Aws::DynamoDB::Client.new(options)
end
