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
class NamesNewCultivarHybridNameSimpleTest < ActionController::TestCase
  tests NamesController

  test "editor should be able to start a new cultivar hybrid name" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "cultivar hybrid",
                  random_id: "123445",
                  tabIndex: "107" },
        session: {},
        xhr: true)
    assert_response :success, "Cannot edit a new cultivar hybrid name"
    assert_select("h4", /New Cultivar Hybrid Name/)
  end

  # The Second parent of a cultivar hybrid being created is the same shared
  # stimulus-autocomplete field as on the edit form, on the cultivar-scoped
  # endpoint. A new name has no id yet, so name_id is sent as null - the
  # autocomplete controller's buildURL turns that into an empty param.
  test "new cultivar hybrid's second parent is a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "cultivar hybrid",
                  random_id: "123445",
                  tabIndex: "107" },
        xhr: true)
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value=" \
                  "'/suggestions/name/cultivar_parent.html']" \
                  " input#name-second-parent-typeahead" \
                  "[data-autocomplete-target='input']",
                  true
    assert_select "div.autocomplete input#name_second_parent_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='name-second-parent-typeahead']",
                  /Second parent/
    assert_no_match(/setUpNameCultivarSecondParentTypeahead\(\)/,
                    @response.body)
    field = css_select("div.autocomplete").find do |div|
      div.css("input#name-second-parent-typeahead").any?
    end
    assert_equal({ "name_id" => nil },
                 JSON.parse(field["data-autocomplete-extra-params-value"]))
  end
end
