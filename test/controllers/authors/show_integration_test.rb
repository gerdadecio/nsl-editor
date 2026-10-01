# frozen_string_literal: true

require "test_helper"

class AuthorShowTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:bentham)
  end

  test "show returns a successful response" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["read"]
    ) do
      get author_tab_path(id: @author.id, tab: "tab_show_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
  end

  test "show response includes the author name" do
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: ["read"]
    ) do
      get author_tab_path(id: @author.id, tab: "tab_show_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_match @author.name.strip, response.body
  end
end
