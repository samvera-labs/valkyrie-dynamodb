# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  require 'valkyrie/persistence/dynamodb/repository'
  class Persister
    attr_reader :adapter
    delegate :connection, :table_name, :resource_factory, to: :adapter
    # @param adapter [Valkyrie::Persistence::DynamoDB::MetadataAdapter] The adapter with the
    #   configured DynamoDB connection.
    def initialize(adapter:)
      @adapter = adapter
    end

    # (see Valkyrie::Persistence::Memory::Persister#save)
    def save(resource:)
      repository([resource]).persist.first
    end

    # (see Valkyrie::Persistence::Memory::Persister#save_all)
    def save_all(resources:)
      repository(resources).persist
    end

    # (see Valkyrie::Persistence::Memory::Persister#delete)
    def delete(resource:)
      repository([resource]).delete.first
    end

    def wipe!
      all_ids = []
      query = { table_name: table_name, attributes_to_get: ['id'] }
      loop do
        resp = connection.scan(query)
        all_ids += resp.items
        break if resp.last_evaluated_key.nil?
        query.merge!(exclusive_key: result.last_evaluated_key)
      end
      all_ids.in_groups_of(25) do |group|
        batch = { request_items: { 'valkyrie_orm' => group.compact.map { |r| { delete_request: { key: r } } } } }
        connection.batch_write_item(batch)
      end
    end

    def repository(resources)
      Valkyrie::Persistence::DynamoDB::Repository.new(resources: resources, connection: connection,
                                                      table_name: table_name, resource_factory: resource_factory)
    end
  end
end
