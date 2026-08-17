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

# Regression test for the structural N+1 fix: Instance::AsArray::ForName
# used to run its own queries once per name it was instantiated for (plus
# once per standalone/relationship instance found within it, plus once per
# instance for this_is_cited_by/profile_items via sort_fields, plus once
# per cited_by-map row for :name), so a caller expanding instances for many
# matching names (e.g. Search::OnName::WithInstances) fired that many extra
# rounds of queries. .preload_for batches those same queries across every
# name given, so the count stops scaling with the number of names.
class InstanceAsArrayForNamePreloadForTest < ActiveSupport::TestCase
  test "preloaded results match what querying each name separately would return" do
    # metrosideros_costata has its own standalone instances plus
    # relationship instances (basionym, synonym) cited by a standalone
    # instance that belongs to a *different* name (angophora_costata) -
    # exercising the citing_ids-not-in-standalone_ids path in preload_for.
    # rusty_gum has a relationship instance cited by yet another
    # standalone instance of metrosideros_costata.
    name_a = names(:metrosideros_costata)
    name_b = names(:angophora_costata)
    name_c = names(:rusty_gum)

    instances_by_name, standalone_map, relationship_map =
      Instance::AsArray::ForName.preload_for([name_a, name_b, name_c])

    [name_a, name_b, name_c].each do |name|
      separately_queried = Instance::AsArray::ForName.new(name).results.map(&:id)
      from_preload = Instance::AsArray::ForName.new(
        name,
        preloaded_instances: instances_by_name[name.id] || [],
        preloaded_standalone_cited_by_map: standalone_map,
        preloaded_relationship_cited_by_map: relationship_map
      ).results.map(&:id)

      assert_equal separately_queried, from_preload,
                   "Batched results for #{name.full_name} should match querying it alone"
    end
  end

  test "preload_for costs far fewer instance-table queries than querying each name separately" do
    names_to_check = [
      names(:metrosideros_costata),
      names(:angophora_costata),
      names(:rusty_gum),
      names(:triodia_basedowii)
    ]

    # Not asserting an exact number for either side (see the equivalent
    # Instance::AsArray::ForReference test) - what matters is that
    # preload_for costs meaningfully less than one Instance::AsArray::ForName
    # per name. Counting Name and Profile::ProfileItem loads too (not just
    # Instance) so this also covers the round-2 fixes (this_is_cited_by/
    # profile_items includes, :name on the cited_by maps) - a regression on
    # any of those would show up here as those per-name queries reappearing.
    batched_count = count_relevant_queries do
      Instance::AsArray::ForName.preload_for(names_to_check)
    end

    per_name_count = count_relevant_queries do
      names_to_check.each { |name| Instance::AsArray::ForName.new(name) }
    end

    assert_operator batched_count, :<, per_name_count,
                     "Expected preload_for (#{batched_count} queries) to cost less than " \
                     "querying these #{names_to_check.size} names one at a time " \
                     "(#{per_name_count} queries)"
  end

  private

  def count_relevant_queries
    count = 0
    callback = lambda do |*args|
      payload = args.last
      count += 1 if payload[:name].to_s.match?(/\A(Instance|Name|Profile::ProfileItem)( Eager)? Load\z/)
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
