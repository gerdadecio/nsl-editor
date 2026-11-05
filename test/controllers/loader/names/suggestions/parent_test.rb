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

# Loader::NamesController#parent_suggestions. Answers the shared html
# fragment to the loader name Parent fields, now on stimulus-autocomplete,
# and still offers json.
class LoaderNameParentSuggestionsTest < ActionDispatch::IntegrationTest
  setup do
    @parent = loader_names(:zzz_test_parent_with_match)
    @batch = loader_batch(:batch_one)
  end

  def get_suggestions(term, format: :html, groups: [ "batch-loader" ], batch_id: @batch.id)
    sign_in_as_fake_user(groups: groups) do
      get loader_names_parent_suggestions_path(format: format),
          params: { term: term, loader_batch_id: batch_id }
    end
  end

  def assert_select_in_body(*args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(response.body),
                  *args, &block)
  end

  # The label is what the library writes back into the input on a pick, and
  # what Loader::Names::ParentTypeahead reads the id back out of.
  test "should get parent suggestions as an html fragment" do
    get_suggestions("zzz test parent with")

    assert_response :success
    assert_select_in_body(
      "li.autocomplete-result[data-autocomplete-value='#{@parent.id}']" \
      "[data-autocomplete-label='#{@parent.simple_name} (#{@parent.id}) ']",
      true
    )
  end

  test "should only offer accepted or excluded names in the batch" do
    get_suggestions("*")

    assert_response :success
    ids = Nokogiri::HTML::DocumentFragment.parse(response.body)
      .css("li[data-autocomplete-value]").map { |li| li["data-autocomplete-value"].to_i }
    assert_includes ids, @parent.id
    assert_not_includes ids, loader_names(:accepted_two).id, "other batch"
    assert_not_includes ids, loader_names(:synonym_guards_pass).id, "synonym"
  end

  test "should not offer the avoided name" do
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      get loader_names_parent_suggestions_path(format: :html),
          params: { term: "zzz test parent with", loader_batch_id: @batch.id, avoid_id: @parent.id }
    end

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  # The instance Loader 2 tab's field can be queried before a batch is chosen.
  test "should render a no matches option when no batch is given" do
    get_suggestions("zzz test parent with", batch_id: "")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  test "should not search several batches at once" do
    get_suggestions("*", batch_id: [ @batch.id, loader_batch(:batch_two).id ])

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select_in_body "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  test "should forbid a user who is not a batch loader" do
    get_suggestions("zzz test parent with", groups: [ "edit" ])

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  test "should still answer json when asked for it" do
    get_suggestions("zzz test parent with", format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).map { |s| s["id"] }, @parent.id
  end
end
