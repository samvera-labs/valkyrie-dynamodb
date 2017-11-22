# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  require 'valkyrie/persistence/dynamodb/queries'
  class QueryService
    attr_reader :adapter, :resource_factory
    delegate :table, :inverse_table, to: :adapter
    # @param connection [RSolr::Client]
    # @param resource_factory [Valkyrie::Persistence::DynamoDB::ResourceFactory]
    def initialize(adapter:, resource_factory:)
      @adapter = adapter
      @resource_factory = resource_factory
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_by)
    def find_by(id:)
      validate_id(id)
      Valkyrie::Persistence::DynamoDB::Queries::FindByIdQuery.new(id, adapter: adapter, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_all)
    def find_all
      Valkyrie::Persistence::DynamoDB::Queries::FindAllQuery.new(adapter: adapter, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_all_of_model)
    def find_all_of_model(model:)
      Valkyrie::Persistence::DynamoDB::Queries::FindAllQuery.new(adapter: adapter, resource_factory: resource_factory, model: model).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_parents)
    def find_parents(resource:)
      find_inverse_references_by(resource: resource, property: :member_ids)
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_members)
    def find_members(resource:, model: nil)
      Valkyrie::Persistence::DynamoDB::Queries::FindMembersQuery.new(resource: resource, model: model,
                                                                     adapter: adapter, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_references_by)
    def find_references_by(resource:, property:)
      Valkyrie::Persistence::DynamoDB::Queries::FindReferencesQuery.new(resource: resource, property: property,
                                                                        adapter: adapter, resource_factory: resource_factory).run
    end

    # (see Valkyrie::Persistence::Memory::QueryService#find_inverse_references_by)
    def find_inverse_references_by(resource:, property:)
      Valkyrie::Persistence::DynamoDB::Queries::FindInverseReferencesQuery.new(resource: resource, property: property,
                                                                               adapter: adapter, resource_factory: resource_factory).run
    end

    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

      def validate_id(id)
        raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
      end
  end
end
