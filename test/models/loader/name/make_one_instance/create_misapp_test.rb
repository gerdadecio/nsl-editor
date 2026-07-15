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

# Loader::Name::MakeOneInstance#create_misapp must check, in this exact
# order, before it is ever safe to look at whether the parent's preferred
# match uses an existing instance:
#   1. does the loader_name have a parent at all?
#   2. does that parent have a preferred match?
#   3. only then: does that match use an existing instance?
# Getting this order wrong raises a NoMethodError on nil instead of
# returning a clean decline, because Loader::Name#preferred_match returns
# nil when there is no preferred match, and belongs_to :parent is optional.
class LoaderNameMakeOneInstanceCreateMisappTest < ActiveSupport::TestCase
  JOB_NUMBER = 999_999

  def creator_for(loader_name_key)
    Loader::Name::MakeOneInstance.new(loader_names(loader_name_key),
                                       "tester",
                                       JOB_NUMBER)
  end

  test "declines with no_parent when the misapp has no parent" do
    result = creator_for(:misapp_no_parent).create_misapp
    assert_equal({declines: 1, declines_reasons: {no_parent: 1}}, result)
  end

  test "declines with parent_no_preferred_match when the parent has " \
       "no preferred match" do
    result = creator_for(:misapp_parent_no_pref_match).create_misapp
    assert_equal({declines: 1,
                  declines_reasons: {parent_no_preferred_match: 1}},
                 result)
  end

  test "declines with parent_is_using_existing_instance when the " \
       "parent's preferred match uses an existing instance" do
    result = creator_for(:misapp_parent_using_existing).create_misapp
    assert_equal({declines: 1,
                  declines_reasons: {parent_is_using_existing_instance: 1}},
                 result)
  end

  test "does not raise once all parent guards pass, and falls through " \
       "to the next check" do
    result = creator_for(:misapp_guards_pass).create_misapp
    assert_equal({declines: 1, declines_reasons: {no_preferred_match: 1}},
                 result)
  end
end
