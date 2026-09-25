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

# Single instance model test.
class InstanceValidationPreventSynonymOfItselfTest < ActiveSupport::TestCase
  test "instance prevent synonym of itself" do
    synonym = instances(:species_or_below_syn_with_genus_or_above)
    assert synonym.valid?, "Starting synonym must be valid for this test."
    synonym.cited_by_id = synonym.cites_id
    synonym.reference_id = synonym.this_is_cited_by.reference.id
    assert_raises(
      ActiveRecord::RecordInvalid,
      "Synonym of itself shouldn't be saved",
    ) do
      synonym.save!
    end
  end
end
