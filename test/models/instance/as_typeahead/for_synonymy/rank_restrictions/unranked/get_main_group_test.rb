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
class TypeaheadForSynonymyUnrankedGetMainGroupTest < ActiveSupport::TestCase
  def setup
    @ta = Instance::AsTypeahead::ForSynonymy.new(
      "a",
      names(:an_unranked_with_an_instance).id
    )
  end

  test "instance typeahead synonymy rank restriction unranked get several" do
    @rank_names = @ta.results.collect do |result|
      Instance.find(result[:id]).name.name_rank.name
    end
    check_1
    check_2
    check_3
    check_4
  end

  def check_1
    check_unranked_inclusion("Subclassis")
    check_unranked_inclusion("Superordo")
    check_unranked_inclusion("Ordo")
    check_unranked_inclusion("Subordo")
    check_unranked_inclusion("Familia")
    check_unranked_inclusion("Subfamilia")
    check_unranked_inclusion("Tribus")
  end

  def check_2
    check_unranked_inclusion("Subtribus")
    check_unranked_inclusion("Genus")
    check_unranked_inclusion("Subgenus")
    check_unranked_inclusion("Sectio")
    check_unranked_inclusion("Subsectio")
    check_unranked_inclusion("Series")
  end

  def check_3
    check_unranked_inclusion("Subseries")
    check_unranked_inclusion("Superspecies")
    check_unranked_inclusion("Species")
    check_unranked_inclusion("Nothovarietas")
    check_unranked_inclusion("Varietas")
    check_unranked_inclusion("Forma")
    check_unranked_inclusion("Subforma")
  end

  def check_4
    check_unranked_inclusion("[infrafamily]")
    check_unranked_inclusion("[infragenus]")
    check_unranked_inclusion("[n/a]")
    check_unranked_inclusion("[infraspecies]")
  end
end
