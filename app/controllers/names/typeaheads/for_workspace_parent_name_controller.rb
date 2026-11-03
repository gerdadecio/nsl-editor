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
class Names::Typeaheads::ForWorkspaceParentNameController < ApplicationController
  include AutocompleteSuggestions

  # Used by the tree workspace Parent fields, see
  # app/views/trees/_update_parent.html.erb (update parent on the draft) and
  # app/views/instances/workspace/forms/_new_placement_name_typeahead.html.erb
  # and _name_typeahead.html.erb (place and replace).
  #
  # Two formats, as for Names::Typeaheads::ForUnpubCitController#index:
  #   html - the fragment stimulus-autocomplete expects, which the field asks
  #          for by extension. Excluded names carry data-excluded="true".
  #   json - what the field asked for while it was on typeahead.js; kept for
  #          parity, and the answer to any other format, as before.
  def index
    # With no draft selected there is nothing to suggest from, and the
    # message below would fail on nil before authorize! ran. Refused like any
    # other denial; the action and subject are set because the
    # ApplicationController's rescue_from logs them.
    if @working_draft.nil?
      raise CanCan::AccessDenied.new("No draft taxonomy selected",
        :names_typeahead_for_workspace_parent,
        TreeVersion)
    end

    authorize!(
      :names_typeahead_for_workspace_parent,
      @working_draft,
      message: "Not authorized to open #{@working_draft.tree.name} typeahead",
    )
    typeahead = Name::AsTypeahead::ForWorkspaceParentName
      .new(params, @working_draft)
    render_autocomplete_suggestions(typeahead.suggestions,
      data_keys: [ :excluded ],
      any_format_as_json: true)
  end

  private

  def typeahead_params
    params.permit(:term)
  end
end
