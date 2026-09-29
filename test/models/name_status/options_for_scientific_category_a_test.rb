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

# Name status options tests.
class OptionsForScientificCategoryATest < ActiveSupport::TestCase
  test "should include default" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("[default]"),
           'Scientific name status options should include "default"'
  end

  test "should include  [deleted]" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("[deleted]"),
           'Scientific name status options should include "[deleted]"'
  end

  test "should include  [n/a]" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("[n/a]"),
           'Scientific name status options should include "[n/a]"'
  end

  test "should include  [unknown]" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("[unknown]"),
           'Scientific name status options should include "[unknown]"'
  end

  test "should include  isonym" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("isonym"),
           'Scientific name status options should include "isonym"'
  end

  test "should include  legitimate" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("legitimate"),
           'Scientific name status options should include "legitimate"'
  end

  test "should include  manuscript" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("manuscript"),
           'Scientific name status options should include "manuscript"'
  end

  test "should include  nom. alt." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. alt."),
           'Scientific name status options should include "nom. alt."'
  end

  test "should include  nom. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. cons."),
           'Scientific name status options should include "nom. cons."'
  end

  test "should include  nom. cons., nom. alt." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. cons., nom. alt."),
           'Scientific name status options need "nom. cons., nom. alt."'
  end

  test "should include  nom. cons., orth. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. cons., orth. cons."),
           'Scientific name status should include "nom. cons., orth. cons."'
  end

  test "should not include  nom. cult." do
    assert_not NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. cult."),
               'Scientific name status options should not include "nom. cult."'
  end
end
