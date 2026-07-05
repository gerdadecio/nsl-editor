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
#  Started GET "/names/new?category=phrase&random_id=3617584730&tabIndex=107"
class NamesNewPhraseNameSimpleTest < ActionController::TestCase
  tests NamesController

  test "editor should be able to start a new phrase name" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "phrase",
                  random_id: "123445",
                  tabIndex: "107" },
        session: {},
        xhr: true)
    assert_response :success, "Cannot edit new phrase name in details tab"
    check_status
  end

  def check_status
    assert_select("h4", /New Phrase Name/)
    assert_select("option", %r{[n/a]})
    selector = 'select[title][required*="required"][name*="name_status_id"]'
    assert_select(selector) do
      assert_select("option[selected]", %r{[n/a]})
    end
  end
end
