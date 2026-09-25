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
class InstanceValidationDoubleSynAllowMisappsTest < ActiveSupport::TestCase
  def setup
    setup_first_syn
    setup_syn
  end

  def setup_first_syn
    @first_syn = instances(:first_syn_for_to_have_a_double)
    @first_syn.instance_type = InstanceType.find_by(name: "misapplied")
    @first_syn.save!
  end

  def setup_syn
    instance_1 = instances(:for_to_have_a_double_in_ref)
    instance_2 = instances(:for_to_be_a_double_in_alt_ref)
    @syn = Instance.new
    @syn.instance_type = InstanceType.find_by(name: "misapplied")
    @syn.this_is_cited_by = instance_1
    @syn.reference = instance_1.reference
    @syn.this_cites = instance_2
    @syn.name = instance_2.name
    @syn.created_by = "tester"
    @syn.updated_by = "tester"
  end

  test "instance double synonym allow misapplications" do
    assert @first_syn.misapplied?, "Need syn to be misapplied in set up."
    assert @syn.name_id == @syn.this_cites.name_id,
      "Name IDs must match for this test."
    assert_difference(
      "Instance.count",
      1,
      "Misapp should not be treated as double synonym",
    ) do
      @syn.save!
    end
  end
end
