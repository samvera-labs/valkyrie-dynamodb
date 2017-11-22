# frozen_string_literal: true
module Valkyrie::Persistence
  module DynamoDB
    require 'valkyrie/persistence/dynamodb/metadata_adapter'
    require 'valkyrie/persistence/dynamodb/persister'
    require 'valkyrie/persistence/dynamodb/query_service'
  end
end
