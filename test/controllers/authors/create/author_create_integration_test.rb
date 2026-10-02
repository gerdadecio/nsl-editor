# frozen_string_literal: true

require "test_helper"

class AuthorCreateTest < ActionDispatch::IntegrationTest
  test "creates an author and increments Author count" do
    assert_difference "Author.count", 1 do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: [ "edit" ]
      ) do
        post authors_path,
          params: { author: { name: "Integration Test Author", abbrev: "I.T.Auth" } },
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :success
  end

  test "does not create an author when name and abbrev are both blank" do
    assert_no_difference "Author.count" do
      sign_in_as_fake_user(
        username: "fred",
        full_name: "Fred Jones",
        groups: [ "edit" ]
      ) do
        post authors_path,
          params: { author: { name: "", abbrev: "" } },
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :unprocessable_content
  end
end
