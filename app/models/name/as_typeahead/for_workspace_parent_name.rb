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
#   A list of names.
class Name::AsTypeahead::ForWorkspaceParentName
  attr_reader :suggestions,
    :params

  SEARCH_LIMIT = 50

  def initialize(params, working_draft)
    @params = params
    @workspace = working_draft
    @suggestions = if @params[:term].blank?
      []
    else
      query
    end
  end

  def prepared_search_term
    @params[:term].tr("*", "%").downcase + "%"
  end

  def basic_query
    @workspace.query_name_in_version(prepared_search_term)
  end

  def query
    if @params[:allow_higher_ranks].to_i > 0
      higher_ranks_query
    else
      normal_query
    end
  end

  # The value is plain text: it is what the field writes back into the input
  # on a pick. An excluded name is flagged with :excluded instead, which the
  # suggestion list shows as a ban icon (see utilities/autocomplete.css). It
  # used to carry the icon's <i> tag in the value, which the old typeahead.js
  # wiring then had to strip back out of the input.
  def normal_query
    this_name = Name.find(@params[:name_id])
    rank_names = this_name.ranks_up_to_next_major.collect { |rank| rank.name }
    @workspace.query_name_version_ranks(prepared_search_term, rank_names)
      .preload(tree_element: :name)
      .collect do |n|
      { value: "#{n.tree_element.name.full_name} - #{n.tree_element.rank}",
        id: n.element_link,
        excluded: n.tree_element.excluded, }
    end
  end

  def higher_ranks_query
    this_name = Name.find(@params[:name_id])
    basic_query
      .joins(tree_element: { name: :name_rank })
      # preload, not includes: includes on the joined path would switch to
      # eager_load, which with basic_query's limit runs an extra DISTINCT query.
      .preload(tree_element: { name: :name_rank })
      .where([ "name_rank.sort_order < ?", this_name.name_rank.sort_order ])
      .collect do |n|
      { value: "#{n.tree_element.name.simple_name} - #{n.tree_element.name.name_rank.name}",
        id: n.element_link,
        excluded: n.tree_element.excluded, }
    end
  end
end
