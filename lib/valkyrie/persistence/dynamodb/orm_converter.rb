# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  ##
  # Converts a dynamodb hash to a {Valkyrie::Resource}
  class ORMConverter
    attr_reader :document
    def initialize(document)
      @document = document.stringify_keys
    end

    def convert!
      resource
    end

    def resource
      resource_klass.new(attributes.symbolize_keys.merge(new_record: false))
    end

    def resource_klass
      internal_resource.constantize
    end

    def internal_resource
      document[Queries::MODEL]
    end

    def attributes
      attribute_hash.merge("id" => id, Queries::MODEL.to_sym => internal_resource, created_at: created_at, updated_at: updated_at)
    end

    def created_at
      DateTime.parse(document["created_at"].to_s).utc
    end

    def updated_at
      DateTime.parse(document["timestamp"] || document["created_at"].to_s).utc
    end

    def id
      document["id"].gsub(/^id-/, '')
    end

    def attribute_hash
      build_literals(document)
    end

    class Property
      attr_reader :key, :value, :document
      def initialize(key, value, document)
        @key = key
        @value = value
        @document = document
      end
    end

    def build_literals(hsh)
      hsh.each_with_object({}) do |(key, value), output|
        next if key.end_with?("_lang")
        next if key.end_with?("_type")
        output[key] = DynamoValue.for(Property.new(key, value, hsh)).result
      end
    end

    class DynamoValue < ::Valkyrie::ValueMapper
    end

    # Converts a stored language typed literal from two fields into one
    #   {RDF::Literal}
    class RDFLiteralPropertyValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.is_a?(Property) &&
          (value.document["#{value.key}_lang"] || value.document["#{value.key}_type"])
      end

      def result
        value.value.each_with_index.map do |literal, idx|
          language = languages[idx]
          type = datatypes[idx]
          if language == "eng" && type == "http://www.w3.org/1999/02/22-rdf-syntax-ns#langString"
            literal
          elsif language.present?
            RDF::Literal.new(literal, language: language, datatype: type)
          else
            RDF::Literal.new(literal, datatype: type)
          end
        end
      end

      def languages
        value.document.fetch("#{value.key}_lang", [])
      end

      def datatypes
        value.document.fetch("#{value.key}_type", [])
      end
    end

    class PropertyValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.is_a?(Property)
      end

      def result
        calling_mapper.for(value.value).result
      end
    end
    class EnumerableValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.respond_to?(:each)
      end

      def result
        value.map do |element|
          calling_mapper.for(element).result
        end
      end
    end

    # Converts a stored ID value in dynamodb into a {Valkyrie::ID}
    class IDValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.to_s.start_with?("id-")
      end

      def result
        Valkyrie::ID.new(value.gsub(/^id-/, ''))
      end
    end

    # Converts a stored URI value in dynamodb into a {RDF::URI}
    class URIValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.to_s.start_with?("uri-")
      end

      def result
        ::RDF::URI.new(value.gsub(/^uri-/, ''))
      end
    end

    # Converts a nested resource in dynamodb into a {Valkyrie::Resource}
    class NestedResourceValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.to_s.start_with?("serialized-")
      end

      def result
        NestedResourceConverter.for(JSON.parse(json, symbolize_names: true)).result
      end

      def json
        value.gsub(/^serialized-/, '')
      end
    end

    class NestedResourceConverter < ::Valkyrie::ValueMapper
    end

    class NestedEnumerable < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)
      def self.handles?(value)
        value.is_a?(Array)
      end

      def result
        value.map do |v|
          calling_mapper.for(v).result
        end
      end
    end

    class NestedResourceID < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)
      def self.handles?(value)
        value.is_a?(Hash) && value[:id] && !value[Queries::MODEL.to_sym]
      end

      def result
        Valkyrie::ID.new(value[:id])
      end
    end

    class NestedResourceURI < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)
      def self.handles?(value)
        value.is_a?(Hash) && value[:@id]
      end

      def result
        RDF::URI(value[:@id])
      end
    end

    class NestedResourceLiteral < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)
      def self.handles?(value)
        value.is_a?(Hash) && value[:@value]
      end

      def result
        RDF::Literal.new(value[:@value], language: value[:@language])
      end
    end

    class NestedResourceHash < ::Valkyrie::ValueMapper
      NestedResourceConverter.register(self)
      def self.handles?(value)
        value.is_a?(Hash)
      end

      def result
        Hash[
          value.map do |k, v|
            [k, calling_mapper.for(v).result]
          end
        ]
      end
    end

    # Converts an boolean in dynamodb into an {Boolean}
    class BooleanValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.to_s.start_with?("boolean-")
      end

      def result
        val = value.sub(/^boolean-/, '')
        val.casecmp("true").zero?
      end
    end

    # Converts an integer in dynamodb into an {Integer}
    class IntegerValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        value.is_a?(BigDecimal)
      end

      def result
        value.to_i
      end
    end

    # Converts a datetime in Solr into a {DateTime}
    class DateTimeValue < ::Valkyrie::ValueMapper
      DynamoValue.register(self)
      def self.handles?(value)
        return false unless value.to_s.start_with?("datetime-")
        DateTime.iso8601(value.gsub(/^datetime-/, '')).utc
      rescue
        false
      end

      def result
        DateTime.parse(value.gsub(/^datetime-/, '')).utc
      end
    end
  end
end
