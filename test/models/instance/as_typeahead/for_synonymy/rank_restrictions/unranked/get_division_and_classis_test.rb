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
require "models/instance/as_typeahead/for_synonymy/rank_restrictions/\
unranked/unranked_helper"

# Single instance typeahead search.
class TypeaheadForSynonymyUnrankedGetDivisionTest < ActiveSupport::TestCase
  def setup
    @ta = Instance::AsTypeahead::ForSynonymy.new(
      "magnolio",
      names(:an_unranked_with_an_instance).id
    )
  end

  test "instance typeahead synonymy rank restriction unranked get division" do
    @rank_names = @ta.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    assert_equal 2, @rank_names.size, "Expect exactly 2 suggestions"
    check_unranked_inclusion("Division")
    check_unranked_inclusion("Classis")
  end
end
