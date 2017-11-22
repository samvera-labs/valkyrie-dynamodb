# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindByIdQuery
    attr_reader :adapter, :resource_factory
    attr_writer :id
    delegate :table, :inverse_table, to: :adapter

    def initialize(id, adapter:, resource_factory:)
      @id = id
      @adapter = adapter
      @resource_factory = resource_factory
    end

    def run
      object = resource
      raise ::Valkyrie::Persistence::ObjectNotFoundError unless object
      resource_factory.to_resource(object: object)
    end

    def id
      @id.to_s
    end

    def resource
      table.get_item(key: { id: id }).to_h[:item]
    end
  end
end
