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
class OptionsForScientificCategoryCTest < ActiveSupport::TestCase
  test "should include  nom. inval., nom. prov." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. prov."),
           'Scientific name status should include "nom. inval., nom. prov."'
  end

  test "should include  nom. inval., nom. subnud." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., nom. subnud."),
           'Scientific name status should include "nom. inval., nom. subnud."'
  end

  test "should include  nom. inval., opera utique oppressa" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., opera utique oppressa"),
           'Scientific name stat shld incl "nom. inval., opera utique oppressa"'
  end

  test "should include  nom. inval., pro syn." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., pro syn."),
           'Scientific name status should include "nom. inval., pro syn."'
  end

  test "should include  nom. inval., tautonym" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. inval., tautonym"),
           'Scientific name status should include "nom. inval., tautonym"'
  end

  test "should include  nom. rej." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. rej."),
           'Scientific name status options should include "nom. rej."'
  end

  test "should include  nom. superfl." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nom. superfl."),
           'Scientific name status options should include "nom. superfl."'
  end

  test "should include  nomina utique rejicienda" do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("nomina utique rejicienda"),
           'Scientific name status should include "nomina utique rejicienda"'
  end

  test "should include  orth. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("orth. cons."),
           'Scientific name status options should include "orth. cons."'
  end

  test "should include  orth. var." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("orth. var."),
           'Scientific name status options should include "orth. var."'
  end

  test "should include  typ. cons." do
    assert NameStatus
      .options_for_category(name_categories(:scientific))
      .collect(&:first)
      .include?("typ. cons."),
           'Scientific name status options should include "typ. cons."'
  end
end
