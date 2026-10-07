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
# Shared setup for the review-vote authorisation tests in this folder.
#
# The voting UI (votes/_votable, _voting_in_progress) only offers a vote when:
#   1. the signed-in user is registered as a Loader::Batch::Reviewer for the review,
#   2. the vote is for the org that reviewer represents,
#   3. that org can_vote, and
#   4. the review has an active review period.
# Also (confirmed with the team, Oct 2026, though the UI does not yet check it):
#   5. the reviewer record must be active.
# (Whether batch_review.allow_voting should also gate voting is deferred.)
# The controllers must enforce the same rules, because org_id and
# batch_review_id arrive as request params and can be changed by the client.
module ReviewVoteTestSetup
  def setup_review_votes
    @review = loader_batch_batch_reviews(:review_one_on_batch_one) # has an active period
    @loader_name = loader_names(:accepted_one)                       # in batch_one, family Apiaceae
    @org_a = make_org("Security Test Org A", "SecOrgA")
    @org_b = make_org("Security Test Org B", "SecOrgB")
    @reviewer_user = users(:reviewer_one)
    @reviewer = make_reviewer(@reviewer_user, @org_a, @review)
  end

  def make_org(name, abbrev, can_vote: true)
    Org.create!(name: name, abbrev: abbrev, can_vote: can_vote,
                created_by: "test", updated_by: "test")
  end

  def make_reviewer(user, org, review)
    Loader::Batch::Reviewer.create!(
      user: user,
      org: org,
      batch_review: review,
      batch_review_role: loader_batch_batch_review_roles(:name_reviewer),
      active: true,
      created_by: "test",
      updated_by: "test",
    )
  end

  def make_vote(org, review: @review, loader_name: @loader_name)
    Loader::Name::Review::Vote.create!(
      loader_name: loader_name, batch_review: review, org: org, vote: true,
      created_by: "test", updated_by: "test",
    )
  end

  def votes_for(org, review: @review)
    Loader::Name::Review::Vote.where(org_id: org.id, batch_review_id: review.id)
  end

  def vote_params(org:, review: @review, loader_name: @loader_name, vote: true)
    { loader_name_review_vote: {
      loader_name_id: loader_name.id,
      batch_review_id: review.id,
      org_id: org.id,
      vote: vote,
    } }
  end

  def as_user(user, &block)
    sign_in_as_fake_user(
      username: user.user_name,
      full_name: user.full_name,
      groups: [ "login", "taxonomic-review" ],
      &block
    )
  end

  # The fix may reject with 403 (CanCan) or 422 (the controllers' existing
  # rescue => create_error); either is acceptable, success is not.
  def assert_rejected
    assert_includes [ 403, 422 ], response.status,
      "Expected the request to be rejected (403/422) but got #{response.status}"
  end
end
