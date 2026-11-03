# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# Print output for loader names shows the simple name, as the web output does.
class SearchLoaderNamesPrintSimpleNameTest < ActionDispatch::IntegrationTest
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

  test "print output shows simple name without authority" do
    search("Hardenbergia violacea any-batch: print:")
    assert_select "span.loader-name.accepted", /Hardenbergia violacea/
    assert_no_match(/A\.W\.Hill/, response.body, "Print output should not show the authority from full_name")
  end

  test "print output handles a synonym with no synonym type" do
    search("Synonym with no parent any-batch: print:")
    assert_select "span.loader-name.synonym", /Synonym with no parent/
  end

  test "web output shows simple name without authority" do
    search("Hardenbergia violacea any-batch:")
    assert_select "span.loader-name.accepted", /Hardenbergia violacea/
    assert_no_match(/A\.W\.Hill/, response.body)
  end
end
