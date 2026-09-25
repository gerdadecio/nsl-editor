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
class OptionsForScientificCategoryBTest < ActiveSupport::TestCase
  test "should not include  nom. cult., nom. alt." do
    assert_not NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. cult., nom. alt."),
      'Scientific name status shld not include "nom. cult., nom. alt."'
  end

  test "should include  nom. et orth. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. et orth. cons."),
      'Scientific name status options should include "nom. et orth. cons."'
  end

  test "should include  nom. et typ. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. et typ. cons."),
      'Scientific name status options should include "nom. et typ. cons."'
  end

  test "should include  nom. illeg." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. illeg."),
      'Scientific name status options should include "nom. illeg."'
  end

  test "should include  nom. illeg., nom. rej." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. illeg., nom. rej."),
      'Scientific name status should include "nom. illeg., nom. rej."'
  end

  test "should include  nom. illeg., nom. superfl." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. illeg., nom. superfl."),
      'Scientific name status should include "nom. illeg., nom. superfl."'
  end

  test "should include  nom. inval." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval."),
      'Scientific name status options should include "nom. inval."'
  end

  test "should include  nom. inval., nom. alt." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. alt."),
      'Scientific name status should include "nom. inval., nom. alt."'
  end

  test "should include  nom. inval., nom. ambig." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. ambig."),
      'Scientific name status should include "nom. inval., nom. ambig."'
  end

  test "should include  nom. inval., nom. confus." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. confus."),
      'Scientific name status should include "nom. inval., nom. confus."'
  end

  test "should not include nom. inval., nom. dub." do
    assert_not NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. dub."),
      'Scientific name status should not include "nom. inval., nom. dub."'
  end

  test "should include  nom. inval., nom. nud." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. nud."),
      'Scientific name status should include "nom. inval., nom. nud."'
  end
end
