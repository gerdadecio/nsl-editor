# frozen_string_literal: true

require "test_helper"

# Distribution cannot be changed for an excluded taxon - update_distribution
# should raise rather than silently continuing (see also
# app/models/concerns/tree/element/profile.rb#update_distribution).
class ExcludedTaxaTest < ActiveSupport::TestCase
  test "cannot update distribution for an excluded taxon" do
    trel = tree_elements(:red_gum_in_taxonomy)
    trel.excluded = true
    assert_nil(trel.distribution_value, "Expect no distribution to start this test")

    error = assert_raises(RuntimeError) do
      trel.update_distribution("WA, NSW", "dist user")
    end

    assert_match(/We don't allow changes to distribution for excluded taxa/i,
                 error.message,
                 "Unexpected message for an excluded taxon distribution update")

    te_unchanged = Tree::Element.find(trel.id)
    assert_nil(te_unchanged.distribution_value,
               "Expected distribution to be unchanged for an excluded taxon")
  end
end
