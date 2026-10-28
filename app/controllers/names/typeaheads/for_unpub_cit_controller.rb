# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#   Names are central to the NSL.
class Names::Typeaheads::ForUnpubCitController < ApplicationController
  include AutocompleteSuggestions

  # Used by the unpublished citation forms' Name field
  # (app/views/instances/_form_create_unpublished_citation.html.erb and
  # app/views/instances/tabs/_tab_unpublished_citation_for_profile_v2.html.erb).
  #
  # Two formats, as for Instances::ChangeNameController#typeahead:
  #   html - the fragment of <li role="option"> elements stimulus-autocomplete
  #          expects, which the Name field asks for by extension.
  #   json - what the field asked for while it was on typeahead.js; kept
  #          for parity with the other suggestion actions, nothing in this
  #          app's own views still asks for it. Also the answer to any other
  #          format, as it was before html was added.
  def index
    typeahead = Name::AsTypeahead::ForUnpubCit.new(params)
    render_autocomplete_suggestions(typeahead.suggestions, any_format_as_json: true)
  end

  private

  def typeahead_params
    params.permit(:term, :name_id)
  end
end
