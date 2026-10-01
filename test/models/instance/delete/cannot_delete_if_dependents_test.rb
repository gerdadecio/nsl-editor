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
class CannotDeleteSynonymIfDependentsTest < ActiveSupport::TestCase
  test "cannot delete synonym with dependents" do
    instance = instances(:angophora_costata_in_stanley)
    dependents = Instance.where(cited_by_id: instance.id).count
    assert dependents.positive?, "The test fixture should have dependents."
    assert_not instance.allow_delete?,
               "Should not be allowed to delete synonym with dependents."
  end
end
