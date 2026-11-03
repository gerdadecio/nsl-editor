# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# The edit tab's "You cannot delete this Author" panel, and the details tab,
# link to a search for each kind of dependent record. Every link must use a
# directive that exists, or the search fails with "Cannot search ... for:
# ...".
class AuthorEditorCannotDeleteLinksTest < ActionDispatch::IntegrationTest
  test "sanctioned names link searches on sanctioning-author-id:" do
    author = authors(:has_sanctioned_one_name_that_is_all)
    links = cannot_delete_links_for(author)
    assert_includes links, [ "names", "sanctioning-author-id:#{author.id} icc:" ]
    assert_links_search_without_error(links)
  end

  # Name search leaves out common and cultivar names unless asked, so the
  # name links carry icc: to find every name the panel counts.
  test "sanctioned names link finds a cultivar name" do
    author = authors(:has_sanctioned_one_name_that_is_all)
    name = names(:has_a_sanctioning_author_that_is_all)
    name.update_columns(name_type_id: name_types(:cultivar).id)
    target, query_string = cannot_delete_links_for(author).assoc("names")
    search = Search::Base.new(ActionController::Parameters.new(query_target: target, query_string: query_string))
    assert_includes search.executed_query.results.map(&:id), name.id
  end

  test "details tab sanctioned names link finds a cultivar name" do
    author = authors(:has_sanctioned_one_name_that_is_all)
    name = names(:has_a_sanctioning_author_that_is_all)
    name.update_columns(name_type_id: name_types(:cultivar).id)
    links = search_links_on(author, "tab_show_1")
    assert_includes links, [ "name", "sanctioning-author-id:#{author.id} icc:" ]
    assert_links_search_without_error(links)
    target, query_string = links.assoc("name")
    search = Search::Base.new(ActionController::Parameters.new(query_target: target, query_string: query_string))
    assert_includes search.executed_query.results.map(&:id), name.id
  end

  test "duplicates link searches on duplicate-of-id:" do
    author = authors(:has_one_duplicate_that_is_all)
    links = cannot_delete_links_for(author)
    assert_includes links, [ "authors", "duplicate-of-id:#{author.id}" ]
    assert_links_search_without_error(links)
  end

  private

  def cannot_delete_links_for(author)
    links = search_links_on(author, "tab_edit")
    assert_match(/You cannot delete this Author/, response.body)
    links
  end

  # [query_target, query_string] for each search link on the tab.
  def search_links_on(author, tab)
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: [ "edit" ]) do
      get author_tab_path(id: author.id, tab: tab),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
    css_select("a[href^='/search']").map do |link|
      query = Rack::Utils.parse_query(URI.parse(link["href"]).query)
      [ query["query_target"], query["query_string"] ]
    end
  end

  def assert_links_search_without_error(links)
    assert links.any?, "Expected search links on the cannot-delete panel"
    links.each do |target, query_string|
      search = Search::Base.new(ActionController::Parameters.new(query_target: target, query_string: query_string))
      assert_not search.error, "#{target} search #{query_string.inspect} failed: #{search.error_message}"
    rescue RuntimeError => e
      flunk "#{target} search #{query_string.inspect} raised: #{e.message}"
    end
  end
end
