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

# Single name model test.
class LanguageOptionsSimpleTest < ActiveSupport::TestCase
  test "options" do
    options = Language.options
    first_set(options)
    second_set(options)
  end

  def try_pair(pair, str)
    assert(pair[0] == str, "Expected #{str}, not #{pair[0]}")
  end

  def first_set(options)
    assert(options[0][0] == "Undetermined", "Unexpected option 0,0")
    try_pair(options[1], "English")
    try_pair(options[2], "French")
    try_pair(options[3], "German")
    try_pair(options[4], "Latin")
  end

  def second_set(options)
    assert(options[5][0] == "──────────", "Missing line separator.")
    assert(options[5][1] == "disabled", "Separator not prepared to be disabled.")
    try_pair(options[6], "Abkhazian")
    try_pair(options.last, "Zuni")
  end
end
