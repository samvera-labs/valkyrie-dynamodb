# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindInverseReferencesQuery
    attr_reader :resource, :property, :adapter, :resource_factory
    delegate :table, :inverse_table, to: :adapter

    def initialize(resource:, property:, adapter:, resource_factory:)
      @resource = resource
      @property = property
      @adapter = adapter
      @resource_factory = resource_factory
    end

    def run
      enum_for(:each)
    end

    def each
      refs = inverse_table.get_item(key: { id: id }).item&.fetch('refs')
      return [] if refs.nil? || refs.empty?
      refs.to_a.in_groups_of(100) do |group|
        batch = query_for(group)
        docs = table.client.batch_get_item(batch).responses[table.table_name].select do |doc|
          Array.wrap(doc[property.to_s]).include?("id-#{id}")
        end
        docs.each do |doc|
          yield resource_factory.to_resource(object: doc)
        end
      end
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

    def id
      resource.id.to_s
    end
  end
end
