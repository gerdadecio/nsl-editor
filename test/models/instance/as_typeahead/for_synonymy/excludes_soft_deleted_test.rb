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

# A soft deleted instance must never be offered as a synonym.
class TypeaheadForSynonymyExcludesSoftDeletedTest < ActiveSupport::TestCase
  test "instance typeahead for synonymy excludes soft deleted instances" do
    before = Instance::AsTypeahead::ForSynonymy.new("angophora",
                                                    names(:a_species).id)
    soft_deleted_id = before.results.first[:id]
    Instance.find(soft_deleted_id).update_column(:deleted_at, Time.current)

    after = Instance::AsTypeahead::ForSynonymy.new("angophora",
                                                   names(:a_species).id)
    assert_not_includes after.results.pluck(:id), soft_deleted_id
    assert_equal before.results.size - 1, after.results.size
  end
end
