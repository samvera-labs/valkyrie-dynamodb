# frozen_string_literal: true
require 'aws-sdk-dynamodb'
module Valkyrie::Persistence::DynamoDB
  require 'valkyrie/persistence/dynamodb/persister'
  require 'valkyrie/persistence/dynamodb/query_service'
  require 'valkyrie/persistence/dynamodb/resource_factory'
  class MetadataAdapter
    attr_reader :connection, :table_name
    # @param connection [Aws::DynamoDB::Client] The DynamoDB connection to index to.
    def initialize(connection: Aws::DynamoDB::Client.new, table_name: 'valkyrie_orm')
      @connection = connection
      @table_name = table_name
      ensure_table_exists!
    end

    # @return [Valkyrie::Persistence::DynamoDB::Persister] The solr persister.
    def persister
      Valkyrie::Persistence::DynamoDB::Persister.new(adapter: self)
    end

    # @return [Valkyrie::Persistence::DynamoDB::QueryService] The solr query
    #   service.
    def query_service
      @query_service ||= Valkyrie::Persistence::DynamoDB::QueryService.new(
        connection: connection,
        table_name: table_name,
        resource_factory: resource_factory
      )
    end

    # @return [Valkyrie::Persistence::DynamoDB::ResourceFactory] A resource factory
    #   to convert a resource to a solr document and back.
    def resource_factory
      Valkyrie::Persistence::DynamoDB::ResourceFactory.new
    end

    private

      def ensure_table_exists!
        return true if connection.list_tables.table_names.include?(table_name)
        connection.create_table table_name: table_name,
                                attribute_definitions: [{ attribute_name: 'id', attribute_type: 'S' }],
                                key_schema: [{ attribute_name: 'id', key_type: 'HASH' }],
                                provisioned_throughput: { read_capacity_units: 1, write_capacity_units: 1 }
      end
  end
end
