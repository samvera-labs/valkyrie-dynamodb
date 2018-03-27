# frozen_string_literal: true
module Valkyrie::Persistence::DynamoDB
  module Queries
    MEMBER_IDS = 'member_ids'
    MODEL = 'internal_resource'
    require 'valkyrie/persistence/dynamodb/queries/find_all_query'
    require 'valkyrie/persistence/dynamodb/queries/find_by_id_query'
    require 'valkyrie/persistence/dynamodb/queries/find_many_by_ids_query'
    require 'valkyrie/persistence/dynamodb/queries/find_inverse_references_query'
    require 'valkyrie/persistence/dynamodb/queries/find_members_query'
    require 'valkyrie/persistence/dynamodb/queries/find_references_query'
  end
end
