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
class NamesNewScientificHybridFormulaSimpleTest < ActionController::TestCase
  tests NamesController

  test "editor should be able to start a new scientific hybrid formula" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "hybrid formula",
                  random_id: "123445",
                  tabIndex: "107" },
        xhr: true)
    assert_response :success,
                    "Cannot get form for a new hybrid formula name"
    assert_select("h4", /New Scientific Hybrid Formula Name/)
  end

  # The First Parent of a hybrid being created is the same shared
  # stimulus-autocomplete field as on the edit form, on the hybrid-scoped
  # endpoint. A new name has no id yet, so name_id is sent as null - the
  # autocomplete controller's buildURL turns that into an empty param.
  test "new scientific hybrid formula's first parent is a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "hybrid formula",
                  random_id: "123445",
                  tabIndex: "107" },
        xhr: true)
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value=" \
                  "'/suggestions/name/hybrid_parent.html']" \
                  " input#name-parent-typeahead" \
                  "[data-autocomplete-target='input'][required]",
                  true
    assert_select "div.autocomplete label[for='name-parent-typeahead']",
                  "First Parent*"
    assert_no_match(/setUpNameHybridParentTypeahead\(\)/, @response.body)
    field = css_select("div.autocomplete").find do |div|
      div.css("input#name-parent-typeahead").any?
    end
    assert_equal({ "name_id" => nil },
                 JSON.parse(field["data-autocomplete-extra-params-value"]))
  end

  test "new scientific hybrid formula's second parent is a stimulus autocomplete" do
    @request.headers["Accept"] = "application/javascript"
    @request.session["username"] = "fred"
    @request.session["user_full_name"] = "Fred Jones"
    @request.session["groups"] = ["edit"]
    get(:new,
        params: { category: "hybrid formula",
                  random_id: "123445",
                  tabIndex: "107" },
        xhr: true)
    assert_response :success
    assert_select "div.autocomplete[data-controller='autocomplete']" \
                  "[data-autocomplete-url-value=" \
                  "'/suggestions/name/hybrid_parent.html']" \
                  " input#name-second-parent-typeahead" \
                  "[data-autocomplete-target='input'][required]",
                  true
    assert_select "div.autocomplete input#name_second_parent_id" \
                  "[data-autocomplete-target='hidden']",
                  true
    assert_select "div.autocomplete label[for='name-second-parent-typeahead']",
                  "Second parent*"
    assert_no_match(/setUpNameSecondParentTypeahead\(\)/, @response.body)
  end
end
