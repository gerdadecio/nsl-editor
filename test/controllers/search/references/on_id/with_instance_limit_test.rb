# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# NSL-6001: a reference search with instance-limit: shows a notice after
# the reference's instances, linking to the next ones, and the summary
# counts instance rows separately from records.
class SearchRefsOnIdWithInstanceLimitTest < ActionDispatch::IntegrationTest
  setup do
    @ref = references(:bucket_reference_for_default_instances)
    @standalone_count = Instance.where(reference_id: @ref.id, cited_by_id: nil).count
  end

  def search(query_string)
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      get search_path, params: { query_target: "references", query_string: query_string }
    end
    assert_response :success
  end

  test "notice shows which instances are listed and links to the next ones" do
    search("id: #{@ref.id} show-instances: instance-limit: 3")
    assert_select "tr.instances-limited-notice", 1 do
      assert_select "td", /Showing instances 1.3\s+of #{@standalone_count}/
      assert_select "a[href*=?]", "instance-offset%3A+3", text: "Show the next instances"
    end
  end

  test "summary counts records and instance rows separately" do
    search("id: #{@ref.id} show-instances: instance-limit: 3")
    assert_select "#search-results-summary", /1 record\b.*\(\d+ instance rows?\)/m
  end

  test "no notice when all instances are shown" do
    search("id: #{@ref.id} show-instances:")
    assert_select "tr.instances-limited-notice", 0
  end

  test "the List more link keeps instance-limit: intact" do
    search("citation: * show-instances: instance-limit: 3 limit: 1")
    links = css_select("#search-results-summary a").map { |a| [ a.text.strip, CGI.unescape(a["href"].to_s) ] }
    more = links.find { |text, _href| text.start_with?("List ") }&.last
    assert more, "Expected a List more link, got: #{links.inspect}"
    assert_includes more, "instance-limit: 3"
    assert_no_match(/(?<![\w-])limit: 1\b/, more, "The old limit: 1 should be replaced")
  end

  test "an invalid instance-limit: shows an error rather than results" do
    search("id: #{@ref.id} show-instances: instance-limit: 0")
    assert_select "tr.instance-within-reference-record", 0
    assert_match(/Invalid instance limit: 0/, response.body)
  end
end
