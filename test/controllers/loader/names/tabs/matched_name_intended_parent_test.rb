# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
#
require "test_helper"

# The matched name tab's Intended Taxonomy Parent field is on the shared
# stimulus-autocomplete markup, not typeahead.js.
class LoaderNameMatchedNameTabIntendedParentTest < ActionDispatch::IntegrationTest
  test "should render the intended parent field as a stimulus autocomplete" do
    loader_name = loader_names(:zzz_test_parent_with_match)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      get loader_name_tab_path(id: loader_name.id, tab: "tab_matched_name"),
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    url = loader_name_matches_suggestions_for_intended_tree_parent_path(format: :html)
    assert_select "div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='#{url}']" \
      "[data-autocomplete-term-delimiter-value='|'] " \
      "input#loader-name-match-intended-tree-parent-name-typeahead" \
      "[data-autocomplete-target='input'][required]:not([name])",
                  true
    assert_select "div.autocomplete " \
      "input#loader_name_match_intended_tree_parent_name_id[data-autocomplete-target='hidden']",
                  true
    assert_select "input[type='submit'][value='Set Intended Parent']", true
    assert_no_match "setUpLoaderNameMatchIntendedTreeParentTypeahead", response.body
  end
end
