# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
#
require "test_helper"

# Loader::Name::Match::Suggestions::ForIntendedTreeParentController#index.
# Answers the shared html fragment to the Intended Taxonomy Parent field,
# now on stimulus-autocomplete, and still offers json.
class LoaderNameMatchIntendedTreeParentSuggestionsTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:angophora_costata)
  end

  def get_suggestions(term, format: :html, groups: [ "batch-loader" ])
    sign_in_as_fake_user(groups: groups) do
      get loader_name_matches_suggestions_for_intended_tree_parent_path(format: format),
          params: { term: term }
    end
  end

  def fragment
    Nokogiri::HTML::DocumentFragment.parse(response.body)
  end

  test "should get intended parent suggestions as an html fragment" do
    get_suggestions("angophora costata")

    assert_response :success
    option = fragment.at_css("li.autocomplete-result[data-autocomplete-value='#{@name.id}']")
    assert option, "Expected an option for #{@name.full_name}"
    assert_match(/\A#{Regexp.escape(@name.full_name)}/, option["data-autocomplete-label"])
  end

  test "should only offer scientific names" do
    get_suggestions("argyle apple")

    assert_response :success
    assert_select fragment, "li[data-autocomplete-value='#{names(:argyle_apple).id}']", false
  end

  test "should render a no matches option for a blank term" do
    get_suggestions("")

    assert_response :success
    assert_select fragment, "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  test "should render a no matches option for an array term" do
    get_suggestions([ "angophora costata" ])

    assert_response :success
    assert_select fragment, "li.autocomplete-result[aria-disabled='true']", text: "No matches"
  end

  test "should forbid a user who is not a batch loader" do
    get_suggestions("angophora costata", groups: [ "edit" ])

    assert_response :forbidden
    assert_no_match "autocomplete-result", response.body
  end

  test "should still answer json when asked for it" do
    get_suggestions("angophora costata", format: :json)

    assert_response :success
    assert_includes JSON.parse(response.body).map { |s| s["id"] }, @name.id
  end
end
