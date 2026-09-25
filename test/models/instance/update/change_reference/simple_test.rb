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
class InstanceUpdateChangeReferenceSimpleTest < ActiveSupport::TestCase
  def setup
    @instance = instances(:britten_created_angophora_costata)
    @instance_back_door = InstanceBackDoor.find(@instance.id)
    @new_reference = references(:a_book)
    @username = "ref-changer"
  end

  test "change reference simple" do
    before
    @instance_back_door.change_reference(
      { "reference_id" => @new_reference.id },
      "ref-changer",
    )
    after
  end

  def before
    assert(
      @instance_back_door.reference_id != @new_reference.id,
      "Reference IDs should start out different.",
    )
    assert(
      @instance_back_door.updated_by != @username,
      "Usernames should start out different.",
    )
    assert_not(@instance.citations.empty?, "Need citations for this test.")
    check_citations_before
  end

  def check_citations_before
    @instance.citations.each do |citation|
      assert(
        citation.reference_id == @instance.reference_id,
        "Should start out pointing to the same reference.",
      )
    end
  end

  def after
    assert(
      @instance_back_door.reference_id == @new_reference.id,
      "Reference IDs should now be the same.",
    )
    assert(
      @instance_back_door.updated_by == @username,
      "Usernames should now be the same.",
    )
    check_citations_after
  end

  def check_citations_after
    @instance.citations.each do |citation|
      citation_back_door = InstanceBackDoor.find(citation.id)
      assert(
        citation_back_door.reference_id == @new_reference.id,
        "Dependent instance should now also point to the new reference.",
      )
      assert(
        citation_back_door.updated_by == @username,
        "Dependent instance should now also point to the new reference.",
      )
    end
  end
end
