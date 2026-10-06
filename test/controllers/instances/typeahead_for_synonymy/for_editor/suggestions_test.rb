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
require "models/instance/as_typeahead/for_synonymy/test_helper"

# InstancesController#typeahead_for_synonymy. Answers the shared html
# fragment to the synonymy tabs' name field, now on stimulus-autocomplete,
# and json, as before, to the change name form's typeahead.
class InstancesTypeaheadForSynonymySuggestionsForEditorTest < ActionDispatch::IntegrationTest
  def get_suggestions(term, format: :html)
    sign_in_as_fake_user(groups: [ "edit" ]) do
      get typeahead_for_synonymy_path(format: format),
          params: { term: term, name_id: names(:a_species).id }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  test "should get synonymy instance suggestions as an html fragment" do
    get_suggestions("angophora costata")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value]" \
      "[data-autocomplete-label=?]",
      ANGOPHORA_COSTATA_JOURNAL_1916_STRING
    )
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']",
                          text: "No matches"
  end

  test "should answer an empty json array for a blank term" do
    get_suggestions("", format: :json)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "should still answer json" do
    get_suggestions("angophora costata", format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).map { |s| s["value"] },
                    ANGOPHORA_COSTATA_JOURNAL_1916_STRING
  end
end
