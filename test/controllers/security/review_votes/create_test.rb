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

# Loader::Name::Review::VotesController#create
class ReviewVotesCreateAuthorisationTest < ActionDispatch::IntegrationTest
  include ReviewVoteTestSetup

  setup { setup_review_votes }

  test "reviewer cannot vote on behalf of an org they do not represent" do
    assert_no_difference(-> { votes_for(@org_b).count }) do
      as_user(@reviewer_user) do
        post create_name_review_vote_path, params: vote_params(org: @org_b),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_rejected
  end

  test "user not registered as a reviewer for the review cannot vote" do
    outsider = users(:user_two)
    assert_no_difference(-> { votes_for(@org_a).count }) do
      as_user(outsider) do
        post create_name_review_vote_path, params: vote_params(org: @org_a),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_rejected
  end

  test "reviewer cannot vote for their org when that org is not a voting org" do
    @org_a.update!(can_vote: false)
    assert_no_difference(-> { votes_for(@org_a).count }) do
      as_user(@reviewer_user) do
        post create_name_review_vote_path, params: vote_params(org: @org_a),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_rejected
  end

  test "reviewer cannot vote in a review that has no active review period" do
    closed_review = Loader::Batch::Review.create!(
      name: "Security test review with no periods",
      loader_batch: @review.loader_batch,
      created_by: "test", updated_by: "test",
    )
    make_reviewer(@reviewer_user, @org_a, closed_review)
    assert_no_difference(-> { votes_for(@org_a, review: closed_review).count }) do
      as_user(@reviewer_user) do
        post create_name_review_vote_path,
          params: vote_params(org: @org_a, review: closed_review),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_rejected
  end

  test "inactive reviewer cannot vote" do
    @reviewer.update!(active: false)
    assert_no_difference(-> { votes_for(@org_a).count }) do
      as_user(@reviewer_user) do
        post create_name_review_vote_path, params: vote_params(org: @org_a),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_rejected
  end

  # Control: the legitimate path must keep working after the fix.
  test "reviewer can vote for the org they represent in an active review" do
    assert_difference(-> { votes_for(@org_a).count }, 1) do
      as_user(@reviewer_user) do
        post create_name_review_vote_path, params: vote_params(org: @org_a),
          headers: { "Accept" => "application/javascript" }, xhr: true
      end
    end
    assert_response :success
  end
end
