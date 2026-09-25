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
require "test_helper"
require "models/name/as_typeahead/cultivar_parent/cultivar_parent_test_helper"

# Single Name typeahead test.
class CultivarParentForUnrankedTest < ActiveSupport::TestCase
  test "name parent suggestion for unranked" do
    avoid_id = 1
    suggestions = Name::AsTypeahead.cultivar_parent_suggestions(
      "%",
      avoid_id,
      NameRank.find_by(name: "[unranked]").id,
    )
    cultivar_parent_suggestions_should_only_include(
      suggestions,
      "[unranked]",
      [
        "[unranked]",
        "Genus",
        "Subgenus",
        "Sectio",
        "Subsectio",
        "Series",
        "Subseries",
        "\n",
        "Superspecies",
        "Species",
        "Subspecies",
        "Varietas",
        "Nothovarietas",
        "Subvarietas",
        "\n",
        "Forma",
        "Subforma"
      ],
    )
  end
end
