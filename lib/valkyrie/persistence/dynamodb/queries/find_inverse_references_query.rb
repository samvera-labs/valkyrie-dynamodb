# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindInverseReferencesQuery
    attr_reader :resource, :property, :connection, :table_name, :resource_factory
    def initialize(resource:, property:, connection:, table_name:, resource_factory:)
      @resource = resource
      @property = property
      @connection = connection
      @table_name = table_name
      @resource_factory = resource_factory
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
      {
        table_name: table_name,
        scan_filter: {
          property => {
            attribute_value_list: ["id-#{resource.id}"],
            comparison_operator: 'CONTAINS'
          }
        }
      }
    end
  end
end
