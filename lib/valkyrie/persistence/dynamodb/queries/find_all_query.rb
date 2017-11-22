# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindAllQuery
    attr_reader :adapter, :resource_factory, :model
    delegate :table, :inverse_table, to: :adapter

    def initialize(adapter:, resource_factory:, model: nil)
      @adapter = adapter
      @resource_factory = resource_factory
      @model = model
    end

    def run
      enum_for(:each)
    end

    def each
      marker = {}
      loop do
        result = table.scan(query.merge(marker))
        result.items.collect do |doc|
          yield resource_factory.to_resource(object: doc)
        end
        marker = { exclusive_key: result.last_evaluated_key }
        break if result.last_evaluated_key.nil?
      end
    end

    def query
      { }.tap do |result|
        if model
          result[:scan_filter] = { MODEL => {
            attribute_value_list: [model.name],
            comparison_operator: 'CONTAINS'
          } }
        end
      end
    end
  end
end
