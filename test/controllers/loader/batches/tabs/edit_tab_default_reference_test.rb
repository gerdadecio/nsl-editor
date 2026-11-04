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

# The loader batch edit tab's Default Reference field is on the shared
# stimulus-autocomplete markup, not typeahead.js.
class LoaderBatchEditTabDefaultReferenceTest < ActionDispatch::IntegrationTest
  setup do
    @loader_batch = loader_batch(:batch_one)
    @reference = references(:cavanilles_icones)
    @loader_batch.update_columns(default_reference_id: @reference.id)
  end

  test "should render the default reference field as a stimulus autocomplete" do
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      get loader_batch_tab_path(id: @loader_batch.id, tab: "tab_edit"),
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    url = loader_batches_default_reference_suggestions_path(format: :html)
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-term-delimiter-value='|'] " \
      "input#loader-batch-default-reference-typeahead[data-autocomplete-target='input']" \
      "[name='loader_batch[default_reference_typeahead]']" \
      "[value='#{@reference.citation}']",
                  true
    assert_select "div.autocomplete " \
      "input#loader_batch_default_reference_id[data-autocomplete-target='hidden']" \
      "[value='#{@reference.id}']",
                  true
    assert_select "div.autocomplete ul[data-autocomplete-target='results']",
                  true
    assert_select "div.autocomplete label[for='loader-batch-default-reference-typeahead']",
                  /Default Reference/
    assert_no_match "setUpLoaderBatchDefaultReferenceTypeahead", response.body
  end
end
