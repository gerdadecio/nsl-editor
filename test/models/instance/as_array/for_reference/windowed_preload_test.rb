# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# NSL-6001: Instance::AsArray::ForReference.preload_for's offset:/limit:
# select standalone instances per reference in SQL, in display order.
class InstanceAsArrayForRefWindowedPreloadTest < ActiveSupport::TestCase
  setup do
    @ref = references(:bucket_reference_for_default_instances)
    @standalone_ids = Instance::AsArray::ForReference
      .windowed_query([ @ref.id ], "name").map(&:id)
    assert_operator @standalone_ids.size, :>, 6, "Fixture precondition: needs more than 6 standalone instances"
  end

  def window_ids(sort_by: "name", offset: 0, limit: nil)
    instances_by_reference, = Instance::AsArray::ForReference
      .preload_for([ @ref ], sort_by: sort_by, offset: offset, limit: limit)
    (instances_by_reference[@ref.id] || []).map(&:id)
  end

  test "preload without offset or limit returns only standalone instances" do
    assert_equal Instance.where(reference_id: @ref.id, cited_by_id: nil).count,
                 window_ids.size
  end

  test "limit returns the first standalone instances in display order" do
    assert_equal @standalone_ids.first(3), window_ids(limit: 3)
  end

  test "consecutive windows neither overlap nor skip" do
    pages = [ window_ids(limit: 3), window_ids(offset: 3, limit: 3), window_ids(offset: 6, limit: 3) ]
    assert_equal @standalone_ids.first(9), pages.flatten
  end

  test "windows follow page order when sorting by page" do
    by_page = Instance::AsArray::ForReference.windowed_query([ @ref.id ], "page").map(&:id)
    assert_equal by_page.first(3), window_ids(sort_by: "page", limit: 3)
    assert_equal by_page[3, 3], window_ids(sort_by: "page", offset: 3, limit: 3)
  end

  test "an offset past the end returns nothing" do
    assert_empty window_ids(offset: @standalone_ids.size, limit: 3)
  end

  test "limit applies per reference, not across references" do
    other = references(:simple)
    instances_by_reference, = Instance::AsArray::ForReference
      .preload_for([ @ref, other ], limit: 2)
    assert_equal 2, instances_by_reference[@ref.id].size
    assert_operator (instances_by_reference[other.id] || []).size, :<=, 2
  end

  test "standalone_counts_for counts standalone instances per reference" do
    counts = Instance::AsArray::ForReference.standalone_counts_for([ @ref.id ])
    assert_equal @standalone_ids.size, counts[@ref.id]
  end
end
