# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindAllQuery
    attr_reader :connection, :table_name, :resource_factory, :model
    def initialize(connection:, table_name:, resource_factory:, model: nil)
      @connection = connection
      @table_name = table_name
      @resource_factory = resource_factory
      @model = model
    end

    def run
      enum_for(:each)
    end

    def each
      marker = {}
      loop do
        result = connection.scan(query.merge(marker))
        result.items.collect do |doc|
          yield resource_factory.to_resource(object: doc)
        end
        break if result.last_evaluated_key.nil?
        marker = { exclusive_key: result.last_evaluated_key }
      end
    end

    def query
      { table_name: table_name }.tap do |result|
        if model
          result[:scan_filter] = { Valkyrie::Persistence::DynamoDB::Queries::MODEL => {
            attribute_value_list: [model.name],
            comparison_operator: 'CONTAINS'
          } }
        end
      end
    end
  end
end
