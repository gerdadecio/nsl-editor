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

class NameDeleteTabDeleteWidgetsTest < ActionController::TestCase
  tests NamesController

  setup do
    @name = names(:another_species)
    @request.headers["Accept"] = "application/javascript"
  end

  def show_delete_tab
    get(:tab,
        params: { id: @name.id, tab: "tab_delete" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: ["edit"] })
  end

  test "shows delete widgets when hard delete is allowed" do
    Name.stub_any_instance(:allow_delete?, true) do
      show_delete_tab
    end
    assert_response :success
    assert_select "a#name-delete-link", "Delete...",
                  "Should show the hard delete link."
    assert_select "a#name-soft-delete-link", false,
                  "Should not show the soft delete link."
  end

  test "shows soft delete widgets when only soft delete is allowed" do
    Name.stub_any_instance(:allow_delete?, false) do
      Name.stub_any_instance(:allow_soft_delete?, true) do
        show_delete_tab
      end
    end
    assert_response :success
    assert_select "a#name-soft-delete-link", "Soft delete name",
                  "Should show the soft delete link."
    assert_select "a#confirm-name-soft-delete-link", "Confirm soft delete",
                  "Should show the confirm soft delete link."
    assert_select "a#cancel-soft-delete-link", "Cancel soft delete",
                  "Should show the cancel soft delete link."
    assert_select "a#name-delete-link", false,
                  "Should not show the hard delete link."
  end

  test "shows soft-deleted message when name is already soft-deleted" do
    Name.stub_any_instance(:allow_delete?, false) do
      Name.stub_any_instance(:allow_soft_delete?, true) do
        Name.stub_any_instance(:deleted_at, Time.current) do
          show_delete_tab
        end
      end
    end
    assert_response :success
    assert_match(/Name has been soft-deleted at/, response.body)
    assert_select "a#name-soft-delete-link", false,
                  "Should not show the soft delete link."
    assert_select "a#name-delete-link", false,
                  "Should not show the hard delete link."
  end

  test "shows no-delete reasons when no delete is allowed" do
    Name.stub_any_instance(:allow_delete?, false) do
      Name.stub_any_instance(:allow_soft_delete?, false) do
        show_delete_tab
      end
    end
    assert_response :success
    assert_match(/Cannot delete:/, response.body)
    assert_select "a#name-delete-link", false,
                  "Should not show the hard delete link."
    assert_select "a#name-soft-delete-link", false,
                  "Should not show the soft delete link."
  end
end
