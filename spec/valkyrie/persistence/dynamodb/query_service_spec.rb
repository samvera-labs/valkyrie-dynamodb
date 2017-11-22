# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Persistence::DynamoDB::QueryService do
  let(:adapter) { Valkyrie::Persistence::DynamoDB::MetadataAdapter.new(connection: client) }
  let(:client)  { dynamodb_client }
  it_behaves_like "a Valkyrie query provider"
end
