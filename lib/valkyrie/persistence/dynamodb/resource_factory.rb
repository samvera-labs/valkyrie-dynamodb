# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  class ResourceFactory
    require 'valkyrie/persistence/dynamodb/orm_converter'
    require 'valkyrie/persistence/dynamodb/model_converter'

    # @param object [Hash] The DynamoDB document in a hash to convert to a
    #   resource.
    # @return [Valkyrie::Resource]
    def to_resource(object:)
      ORMConverter.new(object).convert!
    end

    # @param resource [Valkyrie::Resource] The resource to convert to a DynamoDB hash.
    # @return [Hash] The DynamoDB document represented as a hash.
    def from_resource(resource:)
      Valkyrie::Persistence::DynamoDB::ModelConverter.new(resource, resource_factory: self).convert!
    end
  end
end
