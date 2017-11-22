# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  class ModelConverter
    attr_reader :resource, :resource_factory
    def initialize(resource, resource_factory:)
      @resource = resource
      @resource_factory = resource_factory
    end

    def convert!
      to_h.merge(Valkyrie::Persistence::DynamoDB::Queries::MODEL.to_sym => resource.internal_resource)
    end

    # @return [String] The solr document ID
    def id
      resource.id.to_s
    end

    # @return [String] ISO-8601 timestamp in UTC of the created_at for this solr
    #   document.
    def created_at
      if resource_attributes[:created_at]
        DateTime.parse(resource_attributes[:created_at].to_s).utc.iso8601
      else
        Time.current.utc.iso8601
      end
    end

    # @return [Hash] Solr document to index.
    def to_h
      {
        "id": id,
        "created_at": created_at
      }.merge(attribute_hash)
    end

    private

      def attribute_hash
        properties.each_with_object({}) do |property, hsh|
          attr = resource_attributes[property]
          mapper_val = Array.wrap(DynamoMapperValue.for(Property.new(property, attr)).result)
          mapper_val.each do |val|
            hsh.merge!(val)
          end
        end
      end

      def properties
        resource_attributes.keys - [:id, :created_at, :updated_at]
      end

      def resource_attributes
        @resource_attributes ||= resource.attributes
      end

      ##
      # A container resource for holding a `key`, `value, and `scope` of a value
      # in a resource together for casting.
      class Property
        attr_reader :key, :value, :scope
        # @param key [Symbol] Property identifier.
        # @param value [Object] Value or list of values which are underneath the
        #   key.
        # @param scope [Object] The resource or point where the key and values
        #   came from.
        def initialize(key, value, scope = [])
          @key = key
          @value = value
          @scope = scope
        end
      end

      # Container for casting mappers.
      class DynamoMapperValue < ::Valkyrie::ValueMapper
      end

      # Casts nested resources into a JSON string in solr.
      class NestedObjectValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.value.is_a?(Hash)
        end

        def result
          { value.key => "serialized-#{value.value.to_json}" }
        end
      end

      # Casts enumerable values one by one.
      class EnumerableValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Array)
        end

        def result
          map = value.value.map { |val| calling_mapper.for(Property.new(value.key, val, value.value)).result }
          {}.tap do |hsh|
            map.flatten.each { |v| (hsh[v.keys.first] ||= []) << v.values.first }
          end
        end
      end

      # Skips nil values.
      class NilPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.nil?
        end

        def result
          { value.key => nil }
        end
      end

      # Casts {Valkyrie::ID} values into a recognizable string in solr.
      class IDPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(::Valkyrie::ID)
        end

        def result
          calling_mapper.for(Property.new(value.key, "id-#{value.value.id}")).result
        end
      end

      # Casts {RDF::URI} values into a recognizable string in solr.
      class URIPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(::RDF::URI)
        end

        def result
          calling_mapper.for(Property.new(value.key, "uri-#{value.value}")).result
        end
      end

      # Casts {Integer} values into a recognizable string in Solr.
      class IntegerPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(Integer)
        end

        def result
          { value.key => value.value }
        end
      end

      # Casts {DateTime} values into a recognizable string in Solr.
      class DateTimePropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && (value.value.is_a?(Time) || value.value.is_a?(DateTime))
        end

        def result
          calling_mapper.for(Property.new(value.key, "datetime-#{to_datetime(value.value).xmlschema}")).result
        end

        private

          def to_datetime(value)
            return value.utc if value.is_a?(DateTime)
            return value.to_datetime.utc if value.respond_to?(:to_datetime)
          end
      end

      # Handles casting language-tagged strings when there are both
      # language-tagged and non-language-tagged strings in Solr. Assumes English
      # for non-language-tagged strings.
      class SharedStringPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(String) && value.scope.find { |x| x.is_a?(::RDF::Literal) }.present?
        end

        def result
          [
            calling_mapper.for(Property.new(value.key, value.value)).result,
            calling_mapper.for(Property.new("#{value.key}_lang", "eng")).result
          ]
        end
      end

      # Handles casting strings.
      class StringPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(String)
        end

        def result
          { value.key => value.value }
        end
      end

      # Handles casting language-typed {RDF::Literal}s
      class LiteralPropertyValue < ::Valkyrie::ValueMapper
        DynamoMapperValue.register(self)
        def self.handles?(value)
          value.is_a?(Property) && value.value.is_a?(::RDF::Literal)
        end

        def result
          [
            calling_mapper.for(Property.new(value.key, value.value.to_s)).result,
            calling_mapper.for(Property.new("#{value.key}_lang", value.value.language.to_s)).result
          ]
        end
      end
  end
end
