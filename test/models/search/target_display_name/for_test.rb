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

# NSL-6000: query targets map to their search target dropdown label.
class SearchTargetDisplayNameForTest < ActiveSupport::TestCase
  test "singular and plural targets in any case map to the dropdown label" do
    assert_equal "Names", Search::TargetDisplayName.for("name")
    assert_equal "Names", Search::TargetDisplayName.for("Name")
    assert_equal "Names", Search::TargetDisplayName.for("NAMES")
    assert_equal "References", Search::TargetDisplayName.for("Reference")
    assert_equal "References", Search::TargetDisplayName.for("ref")
    assert_equal "Authors", Search::TargetDisplayName.for("author")
    assert_equal "Instances", Search::TargetDisplayName.for(" Instance ")
    assert_equal "Organisations", Search::TargetDisplayName.for("org")
  end

  test "multi-word targets map to the dropdown label" do
    assert_equal "Names plus instances", Search::TargetDisplayName.for("names PLUS instances")
    assert_equal "Loader names (any batch)", Search::TargetDisplayName.for("loader names (any batch)")
    assert_equal "Bulk processing logs", Search::TargetDisplayName.for("bulk_processing_log")
  end

  test "unlisted targets are returned unchanged" do
    assert_equal "References with novelties", Search::TargetDisplayName.for("References with novelties")
    assert_equal "My Batch 2026", Search::TargetDisplayName.for("My Batch 2026")
  end

  test "blank targets are returned unchanged" do
    assert_nil Search::TargetDisplayName.for(nil)
    assert_equal "", Search::TargetDisplayName.for("")
  end
end
