# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  class Repository
    attr_reader :resources, :adapter, :resource_factory
    delegate :table, :inverse_table, to: :adapter

    def initialize(resources:, adapter:, resource_factory:)
      @resources = resources
      @adapter = adapter
      @resource_factory = resource_factory
    end

    def persist
      documents = resources.map do |resource|
        generate_id(resource) if resource.id.blank?
        db_document(resource)
      end
      documents.in_groups_of(25) do |group|
        batch = group.compact.map { |item| { put_request: { item: item } } }
        table.client.batch_write_item(request_items: { table.table_name => batch })
      end
      update_references('ADD')
      documents.map do |document|
        resource_factory.to_resource(object: document)
      end
    end

    def delete
      update_references('DELETE')
      resources.each do |resource|
        table.delete_item key: { id: resource.id.to_s }
        inverse_table.delete_item key: { id: resource.id.to_s }
      end
    end

    def db_document(resource)
      resource_factory.from_resource(resource: resource).to_h
    end

    def generate_id(resource)
      resource.id = SecureRandom.uuid
    end

    def update_references(action)
      updates = resources.each_with_object({}) do |resource, hsh|
        referents = resource.attributes.values.flatten.uniq.select { |v| v.is_a?(Valkyrie::ID) && v != resource.id }
        referents.each do |ref|
          (hsh[ref.to_s] ||= []) << resource.id.to_s
        end
        hsh
      end

      updates.each_pair do |target, refs|
        inverse_table.update_item({
          key: { id: target },
          update_expression: "#{action} refs :refs",
          expression_attribute_values: { ':refs' => Set.new(refs) }
        })
      end
    end
  end
end
