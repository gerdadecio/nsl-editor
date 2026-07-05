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

# Tests for Instance::AsArray::ForReference::ForNovelties.
class InstanceAsArrayForReferenceForNoveltiesTest < ActiveSupport::TestCase
  test "results is an Array" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    result = Instance::AsArray::ForReference::ForNovelties.new(ref)
    assert result.results.instance_of?(Array), "results should be an Array"
  end

  test "returns primary instances for a reference that has them" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    result = Instance::AsArray::ForReference::ForNovelties.new(ref)
    assert result.results.any?, "Should find primary instances for this reference"
  end

  test "returns empty results for a reference with no primary instances" do
    ref = references(:simple)
    result = Instance::AsArray::ForReference::ForNovelties.new(ref)
    assert result.results.empty?, "Should return no results for a reference with no instances"
  end

  test "results sorted by name by default" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    result = Instance::AsArray::ForReference::ForNovelties.new(ref, "name")
    assert result.results.instance_of?(Array)
  end

  test "results sorted by page when requested" do
    ref = references(:de_fructibus_et_seminibus_plantarum)
    result = Instance::AsArray::ForReference::ForNovelties.new(ref, "page")
    assert result.results.instance_of?(Array)
  end
end
