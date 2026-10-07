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
# Server-side rules for casting or removing a name review vote.
#
# org_id, batch_review_id and loader_name_id all arrive as request params, so
# they must be checked against the signed-in user rather than trusted.
# A vote is allowed only when:
#   - the review exists,
#   - the review has an active review period,
#   - the loader name belongs to the batch under review,
#   - the user is an active reviewer registered for that review,
#   - the vote is for the org that reviewer represents, and
#   - that org is a voting org.
#
# Raises CanCan::AccessDenied (rendered as 403 by ApplicationController).
class Loader::Name::Review::VotePermission
  def self.check!(username:, batch_review_id:, org_id:, loader_name_id:)
    new(username:, batch_review_id:, org_id:, loader_name_id:).check!
  end

  def initialize(username:, batch_review_id:, org_id:, loader_name_id:)
    @username = username
    @batch_review_id = batch_review_id
    @org_id = org_id
    @loader_name_id = loader_name_id
  end

  def check!
    review = Loader::Batch::Review.find_by(id: @batch_review_id)
    deny("That review could not be found") if review.nil?
    deny("This review has no active review period") unless review.periods.active.exists?

    loader_name = Loader::Name.find_by(id: @loader_name_id)
    deny("That name is not part of this review") unless loader_name&.loader_batch_id == review.loader_batch_id

    reviewer = active_reviewer_for(review)
    deny("You are not an active reviewer for this review") if reviewer.nil?
    # A reviewer with no org has org_id nil, which never equals an integer.
    deny("You can only vote on behalf of the organisation you represent") unless reviewer.org_id == @org_id.to_i
    deny("#{reviewer.org.abbrev} is not a voting organisation") unless reviewer.org.can_vote

    reviewer
  end

  private

  def active_reviewer_for(review)
    Loader::Batch::Reviewer
      .username_to_reviewers_for_review(@username, review)
      .where(Loader::Batch::Reviewer.arel_table[:active].eq(true))
      .first
  end

  def deny(message)
    raise CanCan::AccessDenied.new(message, :vote, Loader::Name::Review::Vote)
  end
end
