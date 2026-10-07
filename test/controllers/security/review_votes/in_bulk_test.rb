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

# Loader::Name::Review::Vote::InBulkController#create
# Votes for every accepted/excluded name in the same family and batch, using
# the org_id and batch_review_id from the request.
class ReviewVotesInBulkAuthorisationTest < ActionDispatch::IntegrationTest
  include ReviewVoteTestSetup

  setup { setup_review_votes }

  test "reviewer cannot bulk-vote on behalf of an org they do not represent" do
    as_user(@reviewer_user) do
      post create_name_review_vote_in_bulk_path, params: vote_params(org: @org_b),
        headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_rejected
    assert_equal 0, votes_for(@org_b).count, "No votes should be recorded for Org B"
  end

  test "user not registered as a reviewer cannot bulk-vote" do
    as_user(users(:user_two)) do
      post create_name_review_vote_in_bulk_path, params: vote_params(org: @org_a),
        headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_rejected
    assert_equal 0, votes_for(@org_a).count, "No votes should be recorded for Org A"
  end

  # Control: the legitimate path must keep working after the fix.
  test "reviewer can bulk-vote for the org they represent" do
    as_user(@reviewer_user) do
      post create_name_review_vote_in_bulk_path, params: vote_params(org: @org_a),
        headers: { "Accept" => "application/javascript" }, xhr: true
    end
    assert_response :success
    assert_operator votes_for(@org_a).count, :>=, 1
  end
end
