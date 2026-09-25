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

# Single Name model test.
class NameCultivarHybParentSecondParCanBeTheSameTest < ActiveSupport::TestCase
  test "name cultivar hybrid parent and second parent can be the same" do
    name = names(:a_cultivar_hybrid)
    assert name.parent_id != name.second_parent_id,
      "Name parent and second_parent must differ for this test."
    assert name.valid?,
      "Name should be valid. Errs: #{name.errors.full_messages.join("; ")}"
    name.second_parent_id = name.parent_id
    assert name.valid?,
      "Cultivar Hybrid Name valid even if par is the same as 2nd parent."
  end
end
