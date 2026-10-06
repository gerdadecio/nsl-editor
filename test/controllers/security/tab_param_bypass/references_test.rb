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

# ApplicationController#authorise must not let a ?tab= param stand in for
# the real action on non-tab routes.
#
# A reader (login only, no groups) is granted can("references", "tab_show_1"),
# so before the fix, adding ?tab=tab_show_1 to a write request authorises it
# as if it were a tab view.
class TabParamBypassReferencesTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:simple)
    # Any service call means the request got past the gate.
    stub_request(:any, /localhost:9090/).to_return(status: 200, body: "{}")
  end

  test "reader cannot update a reference by adding a permitted tab param" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      patch reference_path(id: @reference.id, tab: "tab_show_1"),
        params: { reference: { notes: "changed by a reader" } },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
    assert_not_equal "changed by a reader", @reference.reload.notes
  end

  test "reader cannot destroy a reference by adding a permitted tab param" do
    # A copy of a fixture reference with nothing referencing it, so if the gate
    # is bypassed the delete really succeeds (rather than hitting a foreign key).
    disposable = @reference.dup
    disposable.title = "Disposable reference"
    disposable.save!
    assert_no_difference("Reference.count") do
      sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
        delete reference_path(id: disposable.id, tab: "tab_show_1"),
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :forbidden
  end

  test "reader cannot create a reference by adding a permitted tab param" do
    assert_no_difference("Reference.count") do
      sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
        post references_path(tab: "tab_show_1"),
          params: {
            reference: {
              "ref_type_id" => ref_types(:book).id,
              "title" => "Reader-created book",
              "author_id" => authors(:dash).id,
              "author_typeahead" => "-",
              "published" => true,
              "ref_author_role_id" => ref_author_roles(:author).id,
            },
          },
          headers: { "Accept" => "application/javascript" }
      end
    end
    assert_response :forbidden
  end

  test "tab param in the request body is also ignored on write routes" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      patch reference_path(id: @reference.id),
        params: { tab: "tab_show_1", reference: { notes: "changed by a reader" } },
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :forbidden
    assert_not_equal "changed by a reader", @reference.reload.notes
  end

  # Control: the fix must not break legitimate tab viewing for readers.
  test "reader can still view a reference tab they are permitted" do
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      get reference_tab_path(id: @reference.id, tab: "tab_show_1"),
        headers: { "Accept" => "application/javascript" }
    end
    assert_response :success
  end
end
