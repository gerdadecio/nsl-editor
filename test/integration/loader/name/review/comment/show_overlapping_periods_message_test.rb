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

# Single search controller test.
#
# Note:
#   xhr: true
#
# stopped this error in test:
#
# ActionController::InvalidCrossOriginRequest: Security warning:
#   an embedded <script> tag on another site requested protected JavaScript.
class LoaderNameReviewCommentShowTab < ActionController::TestCase
  tests Loader::NamesController


  # Started GET
  # "/nsl/editor/loader_names/52428461/tab/tab_comment/accepted
  # ?format=js&tabIndex=undefined&take_focus=true"
  #
  #  def reviewer_id(username)
  #    reviewers.find_by(user_id: User.find_by_user_name(username)).id
  #  end


  test "show overlapping periods message on comment tab" do
    reviewer = users(:reviewer_one)
    loader_name = loader_names(:accepted_three)
    get('tab',
        params: {id: "#{loader_name.id}", tab: 'tab_comment'},
        format: :js,
        xhr: true,
        session: { username: reviewer.user_name,
                   user_full_name: reviewer.full_name,
                   groups: ["login", "taxonomic-review"]}
       )
    assert_match 'There is more than one active review period for the batch.',
      response.body, "Overlapping review periods should be reported"
  end

  # Regression test: both overlapping periods here belong to the same
  # review ("WG Review" - see review_one_on_batch_three /
  # review_period_overlapping_one/two in the fixtures), so the batch's
  # active_reviews used to list that one review's name twice - one entry
  # per active period, not per distinct review - which read as if there
  # were two different active reviews clashing rather than one review with
  # two overlapping periods.
  test "lists the clashing review once, and names each overlapping period" do
    reviewer = users(:reviewer_one)
    loader_name = loader_names(:accepted_three)
    get('tab',
        params: {id: "#{loader_name.id}", tab: 'tab_comment'},
        format: :js,
        xhr: true,
        session: { username: reviewer.user_name,
                   user_full_name: reviewer.full_name,
                   groups: ["login", "taxonomic-review"]}
       )

    # "WG Review" should appear exactly 3 times: once in the Active
    # reviews line, and once more within each of the two qualified period
    # names below it. Before the fix it appeared a 4th time, as a second,
    # redundant entry in the Active reviews line itself.
    assert_equal 3, response.body.scan("WG Review").size,
      "Expected \"WG Review\" to appear exactly 3 times (once in Active " \
      "reviews, once per period name) - got: " \
      "#{response.body[/Active reviews:.*Active review periods:/m]}"
    assert_match "WG Review Review Period Overlapping One", response.body
    assert_match "WG Review Review Period Overlapping Two", response.body
  end
end
