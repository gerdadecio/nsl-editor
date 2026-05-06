


require "test_helper"

# Single model test.
class LoaderBatchCountActiveReviewPeriodsTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true

  test "Count active review periods" do
    batch = @batch_one
    assert @batch_one.active_review_periods.size == 2,
      "Batch One should have 2 Active Review Periods"
  end
end
