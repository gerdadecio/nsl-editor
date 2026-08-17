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

# Single model test.
#
# qualified_name combines the review's own name with the period's, so two
# periods that share a review (e.g. two overlapping active periods on the
# same review) can still be told apart when listed together - see the
# "Active review periods" list on the comment tab
# (app/views/loader/names/review/tabs/main/_tab_comment.html.erb), which
# this was added for.
class BatchReviewPeriodQualifiedNameTest < ActiveSupport::TestCase
  test "combines the review's name and the period's own name" do
    period = loader_batch_batch_review_batch_review_period(:review_period_overlapping_one)

    assert_equal "WG Review Review Period Overlapping One", period.qualified_name
  end

  test "distinguishes two periods that share the same review" do
    one = loader_batch_batch_review_batch_review_period(:review_period_overlapping_one)
    two = loader_batch_batch_review_batch_review_period(:review_period_overlapping_two)

    assert_equal one.review, two.review, "Fixture setup: both periods should share one review"
    assert_not_equal one.qualified_name, two.qualified_name
  end
end
