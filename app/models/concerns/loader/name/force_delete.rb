# frozen_string_literal: true

module Loader::Name::ForceDelete
  extend ActiveSupport::Concern

  def force_delete
    # start transaction
    #
    # for each child
    #   for each preferred match
    #     delete the match record
    #   end
    #   remove the child
    # end
    # for each preferred match
    #   delete the match record
    # end
    # delete the record
    #
    # end transaction

    loader_name_deleted_ids = []
    ActiveRecord::Base.transaction do
      children.each do |child|
        child.preferred_matches.each do |match|
          match.delete
        end
        loader_name_deleted_ids.push(child.id)
        child.delete
      end
      preferred_matches.each do |match|
        match.delete
      end
      loader_name_deleted_ids.push(id)
      delete
    end # transaction
    loader_name_deleted_ids
  rescue => e
    Rails.logger.error("Error: #{e}")
    []
  end
end
