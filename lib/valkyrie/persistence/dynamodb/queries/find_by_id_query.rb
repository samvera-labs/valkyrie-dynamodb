# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindByIdQuery
    attr_reader :connection, :table_name, :resource_factory
    attr_writer :id
    def initialize(id, connection:, table_name:, resource_factory:)
      @id = id
      @connection = connection
      @table_name = table_name
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
      connection.get_item(key: { id: id }, table_name: table_name).to_h[:item]
    end
  end
end
