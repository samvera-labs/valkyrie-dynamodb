# frozen_string_literal: true
require 'docker/stack/localstack/endpoint_stub'

RSpec.configure do |config|
  config.before(:suite) do
    Docker::Stack::Localstack::EndpointStub.stub_endpoints!
    ignore_resource_error { dynamodb_client.delete_table(table_name: 'valkyrie_orm') }
    ignore_resource_error { dynamodb_client.delete_table(table_name: 'valkyrie_orm.refs') }
  end

  config.before do
    Valkyrie::Persistence::DynamoDB::MetadataAdapter.new(
      connection: dynamodb_client
    ).persister.wipe!
  end
end

# rubocop:disable Lint/HandleExceptions
def ignore_resource_error
  yield
rescue Aws::DynamoDB::Errors::ResourceNotFoundException
end
# rubocop:enable Lint/HandleExceptions

def dynamodb_client
  Aws::DynamoDB::Client.new
end
