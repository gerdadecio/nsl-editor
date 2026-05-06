


require "test_helper"

# Single model test.
class LoaderBatchCountReviewPeriodsTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true

  test "Count review periods" do
    batch = @batch_one
    assert @batch_one.review_periods_in_any_review.size == 2,
      "Batch One should have 2 Review Periods"
  end
end
