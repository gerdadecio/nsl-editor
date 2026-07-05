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

# Nam status options test.
class NameStatusQueryFormOptionsMatchTest < ActiveSupport::TestCase
  test "name status query form options match" do
    options = NameStatus.query_form_options
    # options.each_with_index {|e,i| puts "#{i}: #{e}"}
    first_set(options)
    second_set(options)
    third_set(options)
    fourth_set(options)
    fifth_set(options)
    sixth_set(options)
    seventh_set(options)
  end

  def first_set(options)
    try_pair(options[0], "isonym")
    try_pair(options[1], "legitimate")
    try_pair(options[2], "manuscript")
    try_pair(options[3], "nom. alt.")
  end

  def second_set(options)
    try_pair(options[4], "nom. alt., nom. illeg")
    try_pair(options[5], "nom. cons.")
    try_pair(options[6], "nom. cons., nom. alt.")
    try_pair(options[7], "nom. cons., orth. cons.")
    try_pair(options[8], "nom. cult.")
  end

  def third_set(options)
    try_pair(options[9], "nom. cult., nom. alt.")
    try_pair(options[10], "nom. et orth. cons.")
    try_pair(options[11], "nom. et typ. cons.")
    try_pair(options[12], "nom. illeg.")
    try_pair(options[13], "nom. illeg., nom. rej.")
  end

  def fourth_set(options)
    try_pair(options[14], "nom. illeg., nom. superfl.")
    try_pair(options[15], "nom. inval.")
    try_pair(options[16], "nom. inval., nom. alt.")
    try_pair(options[17], "nom. inval., nom. ambig.")
    try_pair(options[18], "nom. inval., nom. confus.")
  end

  def fifth_set(options)
    try_pair(options[19], "nom. inval., nom. dub.")
    try_pair(options[20], "nom. inval., nom. nud.")
    try_pair(options[21], "nom. inval., nom. prov.")
    try_pair(options[22], "nom. inval., nom. subnud.")
    try_pair(options[23], "nom. inval., opera utique oppressa")
  end

  def sixth_set(options)
    try_pair(options[24], "nom. inval., pro syn.")
    try_pair(options[25], "nom. inval., tautonym")
    try_pair(options[26], "nom. rej.")
    try_pair(options[27], "nom. superfl.")
    try_pair(options[28], "nomina utique rejicienda")
  end

  def seventh_set(options)
    try_pair(options[29], "orth. cons.")
    try_pair(options[30], "orth. var.")
    try_pair(options[31], "typ. cons.")
    try_pair(options[32], "[default]")
    try_pair(options[33], "[deleted]")
    try_pair(options[34], "[n/a]")
    try_pair(options[35], "[unknown]")
  end

  def try_pair(pair, str)
    assert pair[0] == str, "Expected '#{str}', not '#{pair[0]}'"
    assert pair[1] == "status: #{str}",
           "Expected: status #{str}, not #{pair[1]}"
  end
end
