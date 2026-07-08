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

# Instance::Displayable#needs_a_comma? decides whether the "cited by" search
# result line needs a comma between the name and whatever follows it (a name
# status tag and/or a page number).
class Instance::DisplayableTest < ActiveSupport::TestCase
  test "needs a comma when the instance has a page, regardless of status" do
    instance = instances(:britten_created_angophora_costata)
    assert instance.page.present?, "fixture should have a page"
    assert instance.needs_a_comma?
  end

  test "needs a comma when there is no page but the status has display text" do
    instance = instances(:has_no_page_bhl_url_verbatim_name_string)
    assert instance.page.blank?, "fixture should have no page"
    assert instance.name.name_status.name_for_instance_display.present?,
           "fixture status should render display text"
    assert instance.needs_a_comma?
  end

  test "does not need a comma when there is no page and status is legitimate" do
    instance = Instance.new(
      name: names(:a_species),
      reference: references(:dummy_reference_1),
      instance_type: instance_types(:comb_nov),
    )
    assert instance.name.name_status.legitimate?, "fixture status should be legitimate"
    assert instance.page.blank?
    assert_not instance.needs_a_comma?
  end

  test "does not need a comma when there is no page and status is n/a" do
    instance = Instance.new(
      name: names(:argyle_apple),
      reference: references(:dummy_reference_1),
      instance_type: instance_types(:comb_nov),
    )
    assert instance.name.name_status.na?, "fixture status should be n/a"
    assert instance.page.blank?
    assert_not instance.needs_a_comma?
  end

  test "needs a comma when there is a page even if status has no display text" do
    instance = instances(:default_instance_for_a_genus)
    assert instance.page.present?, "fixture should have a page"
    assert instance.name.name_status.legitimate?, "fixture status should be legitimate"
    assert instance.needs_a_comma?
  end
end
