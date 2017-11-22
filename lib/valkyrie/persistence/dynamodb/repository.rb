# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  class Repository
    attr_reader :resources, :table_name, :connection, :resource_factory
    def initialize(resources:, table_name:, connection:, resource_factory:)
      @resources = resources
      @connection = connection
      @table_name = table_name
      @resource_factory = resource_factory
    end

    def persist
      documents = resources.map do |resource|
        generate_id(resource) if resource.id.blank?
        db_document(resource)
      end
      documents.in_groups_of(25) do |group|
        batch = group.compact.map { |item| { put_request: { item: item } } }
        connection.batch_write_item(request_items: { table_name => batch })
      end
      documents.map do |document|
        resource_factory.to_resource(object: document)
      end
    end

    def delete
      resources.each do |resource|
        connection.delete_item key: { id: resource.id.to_s }, table_name: table_name
      end
    end

    def db_document(resource)
      resource_factory.from_resource(resource: resource).to_h
    end

    def generate_id(resource)
      resource.id = SecureRandom.uuid
    end
  end
end
