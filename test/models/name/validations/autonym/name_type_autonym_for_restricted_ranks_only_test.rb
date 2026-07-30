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

# Tests for the name_type_autonym_for_restricted_ranks_only validation.
#
# An autonym is only valid at:
#   - subdivisions of a genus (below genus but above species), and
#   - infraspecific ranks (below species).
# i.e. ranks whose sort_order is greater than genus and which are not species.
#
# Non-autonym name types are unaffected by this validation.
class NameTypeAutonymForRestrictedRanksOnlyTest < ActiveSupport::TestCase
  ERROR = "Name type autonym cannot be this rank"

  def autonym
    names(:autonym_for_rank_validation)
  end

  test "autonym fixture starts out valid (infraspecific rank)" do
    name = autonym
    assert name.valid?,
           "Autonym at subspecies should be valid. " \
           "Errs: #{name.errors.full_messages.join('; ')}"
  end

  test "autonym is valid at an infrageneric rank (subgenus)" do
    name = autonym
    name.name_rank = name_ranks(:subgenus)
    assert name.valid?,
           "Autonym at subgenus should be valid. " \
           "Errs: #{name.errors.full_messages.join('; ')}"
  end

  test "autonym is valid at an infraspecific rank (varietas)" do
    name = autonym
    name.name_rank = name_ranks(:varietas)
    assert name.valid?,
           "Autonym at varietas should be valid. " \
           "Errs: #{name.errors.full_messages.join('; ')}"
  end

  test "autonym is invalid at genus rank" do
    name = autonym
    name.name_rank = name_ranks(:genus)
    assert_not name.valid?, "Autonym at genus should be invalid."
    assert_includes name.errors.full_messages, ERROR
  end

  test "autonym is invalid at species rank" do
    name = autonym
    name.name_rank = name_ranks(:species)
    assert_not name.valid?, "Autonym at species should be invalid."
    assert_includes name.errors.full_messages, ERROR
  end

  test "autonym is invalid at a rank above genus (familia)" do
    name = autonym
    name.name_rank = name_ranks(:familia)
    assert_not name.valid?, "Autonym above genus should be invalid."
    assert_includes name.errors.full_messages, ERROR
  end

  test "non-autonym name type is unaffected at species rank" do
    name = names(:scientific_name)
    assert_equal name_ranks(:species), name.name_rank
    assert name.valid?,
           "Non-autonym scientific name at species should be valid. " \
           "Errs: #{name.errors.full_messages.join('; ')}"
    assert_not_includes name.errors.full_messages, ERROR
  end

  test "switching a valid name to autonym at species makes it invalid" do
    name = names(:scientific_name)
    assert name.valid?, "Scientific name should start out valid."
    name.name_type = name_types(:autonym)
    assert_not name.valid?,
               "Autonym at species rank should not be valid."
    assert_includes name.errors.full_messages, ERROR
  end
end
