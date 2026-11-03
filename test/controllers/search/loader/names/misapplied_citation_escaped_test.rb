# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# A misapplied loader name without misapp_html shows the citation and page of
# its matches. Those are stored values, so they must be escaped, in the web and
# print output alike.
class SearchLoaderNamesMisappliedCitationEscapedTest < ActionDispatch::IntegrationTest
  QUERY = "Misapp matched with cross ref any-batch:"

  setup do
    match = loader_name_matches(:match_misapp_matched_with_cross_ref)
    match.instance.reference.update_column(:citation, "<b>bold</b> Gaertner, De Fructibus")
    match.instance.update_column(:page, "<script>alert(1)</script>12")
  end

  def search(query_string)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ :login, :"batch-loader" ]
    ) do
      get search_path, params: { query_target: "loader names", query_string: query_string }
    end
    assert_response :success
  end

  def assert_citation_escaped
    assert_no_match(/<script>alert/, response.body, "Stored page should be escaped")
    assert_no_match(%r{<b>bold</b>}, response.body, "Stored citation should be escaped")
    assert_match(/&lt;b&gt;bold&lt;\/b&gt; Gaertner, De Fructibus: &lt;script&gt;alert\(1\)&lt;\/script&gt;12\]/,
                 response.body)
  end

  test "web output escapes the citation and page" do
    search(QUERY)
    assert_citation_escaped
  end

  test "print output escapes the citation and page" do
    search("#{QUERY} print:")
    assert_citation_escaped
  end

  test "pro parte match still shows p.p. in italics" do
    loader_name_matches(:match_misapp_matched_with_cross_ref)
      .update_column(:relationship_instance_type_id, instance_types(:doubtful_pro_parte_misapplied).id)
    search("#{QUERY} print:")
    assert_match(%r{: &lt;script&gt;alert\(1\)&lt;/script&gt;12, <i>p\.p\.</i>\]}, response.body)
  end
end
