# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# NSL-6065: after a name is edited, the response refreshes the name's link
# in the search results (LHS). Name rows from a plain name search and from
# a search showing instances used to have different ids (name-123 and
# Name-123), and the response only found the first, so the LHS kept the old
# name after a show-instances: search. Both rows now use Name#anchor_id.
class NamesEditRefreshLhsLinkAfterUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @name = names(:acacia)
    stub_request(:get, %r{nsl/services/rest/name/apni/[0-9]+/api/name-strings})
      .to_return(status: 200,
                 body: { result: { simpleName: "Acacia", fullName: "Acacia" } }.to_json,
                 headers: {})
  end

  def search(query_string)
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: [ "edit" ]) do
      get search_path, params: { query_target: "name", query_string: query_string }
    end
    assert_response :success
  end

  test "a plain name search gives the name's link its anchor id" do
    search("id: #{@name.id}")
    assert_select "a#Name-#{@name.id}", 1
    assert_select "a#name-#{@name.id}", 0
  end

  test "a show-instances: search gives the name's link the same anchor id" do
    search("id: #{@name.id} show-instances:")
    assert_select "a#Name-#{@name.id}", 1
  end

  test "the update response refreshes the link by its anchor id" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: [ "edit" ]) do
      patch name_path(id: @name.id),
        params: { name: { "verbatim_rank" => "gen. changed" } },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    assert_includes response.body, "$('a#Name-#{@name.id}').html("
    assert_not_includes response.body, "a#name-#{@name.id}"
  end
end
