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

# Tree::ElementsController#update_profile.
#
# A raised error while updating the distribution part of the profile (e.g.
# an excluded taxon, or an invalid distribution value) must short-circuit
# the whole action: render the error view with 422, and leave any pending
# comment change unapplied - see app/models/concerns/tree/element/profile.rb.
class TreeElementsControllerTest < ActionController::TestCase
  tests Tree::ElementsController

  def valid_session
    { username: "fred", user_full_name: "Fred Jones", groups: %w[edit treebuilder] }
  end

  test "distribution error on an excluded taxon renders the error view and skips the comment update" do
    trel = tree_elements(:red_gum_in_taxonomy)
    trel.update_column(:excluded, true)
    assert_nil(trel.comment_value, "Expect no comment to start this test")

    @request.headers["Accept"] = "application/javascript"
    patch(:update_profile,
          params: { id: trel.id,
                    tree_element: { distribution_value: "WA, NSW",
                                    comment_value: "should not be applied" } },
          session: valid_session)

    assert_response :unprocessable_content
    assert_template "update_profile_error"
    assert_match(/Distribution update error:.*excluded taxa/i, assigns(:message))
    assert_nil(assigns(:comment_message),
               "Comment should never have been processed")

    te_unchanged = Tree::Element.find(trel.id)
    assert_nil(te_unchanged.comment_value,
               "Expected comment to be unchanged when the distribution update errors")
  end

  test "a normal distribution and comment update succeeds" do
    trel = tree_elements(:red_gum_in_taxonomy)
    assert_nil(trel.profile, "Expect no profile to start this test")

    @request.headers["Accept"] = "application/javascript"
    patch(:update_profile,
          params: { id: trel.id,
                    tree_element: { distribution_value: "NSW, WA",
                                    comment_value: "a new comment" } },
          session: valid_session)

    assert_response :success
    assert_template "update_profile"
    assert_match(/Distribution added/i, assigns(:distribution_message))
    assert_match(/Comment added/i, assigns(:comment_message))

    te_changed = Tree::Element.find(trel.id)
    assert_equal("a new comment", te_changed.comment_value)
    assert_not_nil(te_changed.distribution_value)
  end
end
