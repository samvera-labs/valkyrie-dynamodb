# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB::Queries
  class FindMembersQuery
    attr_reader :resource, :adapter, :resource_factory, :model
    delegate :table, :inverse_table, to: :adapter

    def initialize(resource:, adapter:, resource_factory:, model:)
      @resource = resource
      @adapter = adapter
      @resource_factory = resource_factory
      @model = model
    end

    def run
      enum_for(:each)
    end

    def each
      return [] unless resource.id.present? && resource.respond_to?(:member_ids)
      unordered_members.sort_by { |x| member_ids.index(x.id) }.each do |member|
        yield member
      end
    end

    def unordered_members
      docs.map do |doc|
        resource_factory.to_resource(object: doc)
      end
    end

    def docs
      result = []
      member_ids.in_groups_of(100) do |group|
        batch = query_for(group)
        result += table.client.batch_get_item(batch).responses[table.table_name].select do |doc|
          model.nil? || doc[MODEL] == model.name
        end
      end
      result
    end

    def member_ids
      Array.wrap(resource.member_ids)
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
