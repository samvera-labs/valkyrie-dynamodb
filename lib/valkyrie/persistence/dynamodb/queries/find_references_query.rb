# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindReferencesQuery
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
      refs = resource.attributes[property]
      Array.wrap(refs).in_groups_of(100) do |group|
        batch = query_for(group)
        docs = connection.batch_get_item(batch).responses[table_name]
        docs.each do |doc|
          yield resource_factory.to_resource(object: doc)
        end
      end
    end

    def query_for(group)
      {
        request_items: {
          table_name => {
            keys: group.compact.map { |ref| { 'id' => ref.to_s } }
          }
        }
      }
    end
  end
end
