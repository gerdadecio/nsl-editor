# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# The response every suggestion action gives its stimulus-autocomplete field.
#
# Two response formats over the one list of suggestions:
#   json - what the fields asked for while they were on typeahead.js; kept
#          for parity, nothing in this app's own views still asks for it.
#   html - the fragment of <li role="option"> elements stimulus-autocomplete
#          expects, see app/views/shared/_autocomplete_suggestions.html.erb.
#          The fields ask for it by extension.
#
# json is declared first on purpose. stimulus-autocomplete sends no Accept
# header of its own, so a caller with no extension gets whichever format is
# declared first - see AuthorsController#typeahead_on_abbrev's comment.
#
# any_format_as_json also answers any other format (e.g. an
# "application/javascript" Accept header) with json, for the actions that
# did so before html was added. The others answer such a request with 406,
# as they always have.
#
# data_keys is passed through to the partial, which publishes those keys
# of each suggestion as data attributes on its option.
module AutocompleteSuggestions
  extend ActiveSupport::Concern

  private

  def render_autocomplete_suggestions(suggestions, data_keys: [], any_format_as_json: false)
    respond_to do |format|
      format.json { render(json: suggestions) }
      format.html do
        render(
          partial: "shared/autocomplete_suggestions",
          locals: { suggestions: suggestions, term: params[:term], data_keys: data_keys },
        )
      end
      format.any { render(json: suggestions) } if any_format_as_json
    end
  end
end
