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

# Single controller test.
class NamesNewScientHybridFormulaUnk2ParSimpleTest < ActionDispatch::IntegrationTest
  test "editor start new scientific hybrid formula unk 2nd parent" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["edit"]
    ) do
      get new_name_with_category_and_random_id_path(category: "hybrid formula unknown 2nd parent", random_id: "123445"),
        params: { tabIndex: "107" },
        headers: { "Accept" => "application/javascript" },
        xhr: true
    end
    assert_response :success,
                    "Cannot open form for a new scientific hybrid formula
                    unknown 2nd parent name"
    assert_select("h4", /New Scientific Hybrid Formula Unknown 2nd Parent Name/)
  end
end
