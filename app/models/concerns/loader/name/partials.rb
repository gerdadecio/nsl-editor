# frozen_string_literal: true

module Loader::Name::Partials
  extend ActiveSupport::Concern

  # synonym_type takes precedence
  def partial_misapplied?
    if synonym_type.blank?
      publ_partly&.match(/p\.p\./)
    else
      synonym_type&.match?(/pro parte/)
    end
  end

  def partial_or_match_is_partial?
    synonym_type&.match?(/pro parte/) |
      preferred_match&.relationship_instance_type&.pro_parte?
  end
end
