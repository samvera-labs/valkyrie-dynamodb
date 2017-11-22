# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  require 'valkyrie/persistence/dynamodb/repository'
  class Persister
    attr_reader :adapter
    delegate :table, :inverse_table, :resource_factory, to: :adapter
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
      wipe_table!(table)
      wipe_table!(inverse_table)
    end

    def repository(resources)
      Valkyrie::Persistence::DynamoDB::Repository.new(resources: resources, adapter: adapter, resource_factory: resource_factory)
    end

    private

      def wipe_table!(target)
        all_ids = []
        query = { attributes_to_get: ['id'] }
        loop do
          resp = target.scan(query)
          all_ids += resp.items
          query[:exclusive_key] = resp.last_evaluated_key
          break if resp.last_evaluated_key.nil?
        end
        all_ids.in_groups_of(25) do |group|
          batch = { request_items: { target.table_name => group.compact.map { |r| { delete_request: { key: r } } } } }
          target.client.batch_write_item(batch)
        end
      end
  end
end
