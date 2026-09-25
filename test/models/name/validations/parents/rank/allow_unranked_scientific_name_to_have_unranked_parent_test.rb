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
class AllowUnrankedNameToHaveUnrankedParentTest < ActiveSupport::TestCase
  test "unranked scientific name having unranked parent" do
    name = names(:unranked_scientific_name_with_unranked_parent)
    assert name.valid?,
      "Name should be valid. Errs: #{name.errors.full_messages.join("; ")}"
  end
end
