# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindManyByIdsQuery
    attr_reader :adapter, :resource_factory
    attr_accessor :ids
    delegate :table, :inverse_table, to: :adapter

    def initialize(ids, adapter:, resource_factory:)
      @ids = Array.wrap(ids)
      @adapter = adapter
      @resource_factory = resource_factory
    end

    def run
      enum_for(:each)
    end

    def each
      return [] if @ids.empty?
      docs.map do |doc|
        yield resource_factory.to_resource(object: doc)
      end
    end

    def docs
      result = []
      ids.in_groups_of(100) do |group|
        batch = query_for(group)
        result += table.client.batch_get_item(batch).responses[table.table_name]
      end
      result
    end

    def query_for(group)
      {
        request_items: {
          table.table_name => {
            keys: group.compact.map do |ref|
              { 'id' => ref.to_s }
            end
          }
        }
      }
    end
  end
end
