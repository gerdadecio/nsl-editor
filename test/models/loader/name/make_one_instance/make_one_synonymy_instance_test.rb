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

# Loader::Name::MakeOneInstance::MakeOneSynonymyInstance#create must check,
# in this exact order, before it is ever safe to look at whether the
# parent's preferred match uses an existing instance:
#   1. does the relationship instance already exist for the synonym's own
#      match? (pre-existing check, unaffected by this)
#   2. does the loader_name have a parent at all?
#   3. does that parent have a preferred match?
#   4. only then: does that match use an existing instance?
# Getting 2-4 out of order raises a NoMethodError on nil instead of
# returning a clean decline, because Loader::Name#preferred_match returns
# nil when there is no preferred match, and belongs_to :parent is optional.
class LoaderNameMakeOneInstanceMakeOneSynonymyInstanceTest < ActiveSupport::TestCase
  JOB_NUMBER = 999_999

  def creator_for(loader_name_key)
    Loader::Name::MakeOneInstance::MakeOneSynonymyInstance.new(
      loader_names(loader_name_key), "tester", JOB_NUMBER
    )
  end

  test "declines with synonym_has_no_parent when the synonym has no parent" do
    result = creator_for(:synonym_no_parent).create
    assert_equal({declines: 1, declines_reasons: {synonym_has_no_parent: 1}},
                 result)
  end

  test "declines with parent_no_preferred_match when the parent has " \
       "no preferred match" do
    result = creator_for(:synonym_parent_no_pref_match).create
    assert_equal({declines: 1,
                  declines_reasons: {parent_no_preferred_match: 1}},
                 result)
  end

  test "declines with parent_is_using_existing_instance when the " \
       "parent's preferred match uses an existing instance" do
    result = creator_for(:synonym_parent_using_existing).create
    assert_equal({declines: 1,
                  declines_reasons: {parent_is_using_existing_instance: 1}},
                 result)
  end

  test "does not raise once all parent guards pass, and falls through " \
       "to the next check" do
    result = creator_for(:synonym_guards_pass).create
    assert_equal({declines: 1,
                  declines_reasons: {parent_has_no_standalone_instance: 1}},
                 result)
  end
end
