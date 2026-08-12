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

# Regression test for the structural N+1 fix: Instance::AsArray::ForReference
# used to run its own queries once per reference it was instantiated for, so
# a caller expanding instances for many matching references (e.g.
# Search::OnModel::Base#show_instances) fired that many extra rounds of
# queries. .preload_for batches those same queries across every reference
# given, so the count stops scaling with the number of references.
class InstanceAsArrayForReferencePreloadForTest < ActiveSupport::TestCase
  test "preloaded results match what querying each reference separately would return" do
    ref_a = references(:bucket_reference_for_default_instances)
    ref_b = references(:paper_by_britten_on_angophora)

    instances_by_reference, cited_by_map =
      Instance::AsArray::ForReference.preload_for([ref_a, ref_b])

    [ref_a, ref_b].each do |ref|
      separately_queried = Instance::AsArray::ForReference.new(ref).results.map(&:id)
      from_preload = Instance::AsArray::ForReference.new(
        ref, "name", 1000, 0,
        preloaded_instances: instances_by_reference[ref.id] || [],
        preloaded_cited_by_map: cited_by_map
      ).results.map(&:id)

      assert_equal separately_queried, from_preload,
                   "Batched results for #{ref.citation} should match querying it alone"
    end
  end

  test "preload_for costs far fewer instance-table queries than querying each reference separately" do
    # Five existing fixture references that each already have at least one
    # instance, so this doesn't need to fabricate new Reference records
    # (which have several other required associations of their own).
    refs = [
      references(:bucket_reference_for_default_instances),
      references(:paper_by_britten_on_angophora),
      references(:part_about_metrosideros_costata),
      references(:de_fructibus_et_seminibus_plantarum),
      references(:stanley_in_stanley_and_ross)
    ]

    # Not asserting an exact number for either side: how many
    # instance-table queries a single reference costs varies with what
    # it contains (e.g. built_query's includes(this_is_cited_by: ...) only
    # adds its own batched preload query for references with an instance
    # that has this_is_cited_by set). What matters is the comparison - if
    # preload_for were still querying per-reference under the hood, it
    # would cost roughly the same as the one-at-a-time loop below, not
    # meaningfully less.
    batched_count = count_instance_table_queries do
      Instance::AsArray::ForReference.preload_for(refs)
    end

    per_reference_count = count_instance_table_queries do
      refs.each { |ref| Instance::AsArray::ForReference.new(ref) }
    end

    assert_operator batched_count, :<, per_reference_count,
                     "Expected preload_for (#{batched_count} queries) to cost less than " \
                     "querying these #{refs.size} references one at a time " \
                     "(#{per_reference_count} queries)"
  end

  private

  def count_instance_table_queries
    count = 0
    callback = lambda do |*args|
      payload = args.last
      count += 1 if payload[:name].to_s.match?(/\AInstance( Eager)? Load\z/)
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
