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
require_relative "review_vote_test_setup"

# Loader::Name::Review::VotesController#destroy
# The vote is looked up by (org_id, batch_review_id, loader_name_id) taken
# from the URL, with no check that it belongs to the current reviewer's org.
class ReviewVotesDestroyAuthorisationTest < ActionDispatch::IntegrationTest
  include ReviewVoteTestSetup

  setup { setup_review_votes }

  test "reviewer cannot delete another org's vote" do
    other_orgs_vote = make_vote(@org_b)
    as_user(@reviewer_user) do
      delete delete_name_review_vote_path(
        loader_name_id: @loader_name.id, batch_review_id: @review.id, org_id: @org_b.id,
      ), headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_rejected
    assert Loader::Name::Review::Vote.exists?(
      org_id: other_orgs_vote.org_id,
      batch_review_id: other_orgs_vote.batch_review_id,
      loader_name_id: other_orgs_vote.loader_name_id,
    ), "Org B's vote should not have been deleted"
  end

  test "user not registered as a reviewer cannot delete a vote" do
    make_vote(@org_a)
    as_user(users(:user_two)) do
      delete delete_name_review_vote_path(
        loader_name_id: @loader_name.id, batch_review_id: @review.id, org_id: @org_a.id,
      ), headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_rejected
    assert_equal 1, votes_for(@org_a).count, "Org A's vote should not have been deleted"
  end

  # Control: the legitimate path must keep working after the fix.
  test "reviewer can delete their own org's vote" do
    make_vote(@org_a)
    as_user(@reviewer_user) do
      delete delete_name_review_vote_path(
        loader_name_id: @loader_name.id, batch_review_id: @review.id, org_id: @org_a.id,
      ), headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_response :success
    assert_equal 0, votes_for(@org_a).count
  end
end
