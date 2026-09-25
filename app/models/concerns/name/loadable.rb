# frozen_string_literal: true

#
# Names can be in a loader batch
module Name::Loadable
  extend ActiveSupport::Concern

  def matched_to_loader_name?
    matches.size > 0
  rescue StandardError => e
    Rails.logger.error("Error checking matched_to_loader_name: #{e}")
    false
  end

  def matches
    ::Loader::Name::Match.where(name_id: id)
  rescue StandardError => e
    Rails.logger.error("Error checking matches: #{e}")
    []
  end
end
