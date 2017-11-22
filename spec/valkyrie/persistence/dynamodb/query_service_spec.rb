# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Valkyrie::Persistence::DynamoDB::QueryService do
  let(:adapter) { Valkyrie::Persistence::DynamoDB::MetadataAdapter.new(connection: client) }
  let(:client)  { dynamodb_client }
  it_behaves_like "a Valkyrie query provider"

  describe "invalid datetime" do
    before do
      class CustomResource < Valkyrie::Resource
        attribute :id, Valkyrie::Types::ID.optional
        attribute :foo
      end
    end
    after do
      Object.send(:remove_const, :CustomResource)
    end

    let(:resource) { adapter.persister.save(resource: CustomResource.new(foo: ['datetime-psych!'])) }
    let(:reloaded_resource) { adapter.query_service.find_by(id: resource.id) }

    it "falls through to the string handler" do
      expect(reloaded_resource.foo).to eq(['datetime-psych!'])
    end
  end
end
