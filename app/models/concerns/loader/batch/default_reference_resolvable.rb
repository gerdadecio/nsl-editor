# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# Loader batch Default Reference typeahead params are resolvable.
#
# The form's Default Reference field sends the visible text and a hidden id.
# stimulus-autocomplete empties the hidden id whenever the text is edited,
# so the id alone can't be trusted: the text is resolved instead.
#   - blank text clears the default reference
#   - text matching one citation sets that reference
#   - anything else raises "please choose Default Reference from
#     suggestions", rather than silently saving no reference
#
# The resolver matches any reference, so a match the field's suggestions
# would never offer (a Journal or a duplicate, see
# Reference::AsTypeahead::OnCitation) is refused the same way.
module Loader::Batch::DefaultReferenceResolvable
  extend ActiveSupport::Concern

  DEFAULT_REFERENCE_PARAMS = %w[default_reference_id default_reference_typeahead].freeze

  # Leaves the default reference alone if the params don't carry the field.
  def resolve_default_reference(params)
    return unless params.key?("default_reference_typeahead")

    id = Reference::AsResolvedTypeahead::ForDuplicateOf.new(
      params["default_reference_id"],
      params["default_reference_typeahead"],
      "Default Reference",
    ).value.presence
    raise "please choose Default Reference from suggestions" if id.present? && !offered_as_default_reference?(id)

    self.default_reference_id = id
  end

  private

  # Same filters as the suggestions: no Journals, no duplicates.
  def offered_as_default_reference?(id)
    Reference.joins(:ref_type)
      .where.not(ref_type: { name: "Journal" })
      .not_duplicate
      .exists?(id)
  end
end
