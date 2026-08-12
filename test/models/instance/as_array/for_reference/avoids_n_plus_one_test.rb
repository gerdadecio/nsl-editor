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

# Regression test for the N+1 fix in
# Instance::AsArray::ForReference#find_instances_for_ref.
#
# Before the fix, include_standalone_instance_and_synonymy called
# instance.is_cited_by once per standalone instance - each call its own
# query with 4 joins and a raw-SQL synonymy sort - so the number of
# "Instance Load" queries scaled linearly with the number of standalone
# instances on the reference. After the fix, every standalone instance's
# citing instances are fetched in a single batched query
# (fetch_cited_by_map), so the query count stays constant however many
# standalone instances there are.
class InstanceAsArrayForReferenceAvoidsNPlusOneTest < ActiveSupport::TestCase
  STANDALONE_COUNT = 5

  setup do
    @ref = references(:bucket_reference_for_default_instances)
    @standalones = Array.new(STANDALONE_COUNT) do |n|
      Instance.create!(
        namespace: namespaces(:apni),
        created_by: "tester",
        updated_by: "tester",
        reference: @ref,
        name: names(:the_regnum),
        # comb_et_stat_nov is standalone: true but NOT primary_instance: true
        # (unlike comb_nov) - the_regnum's fixture already has a primary
        # (comb_nov) instance, and only_one_primary_instance_per_name only
        # allows one primary instance per name across the whole system, so
        # a second comb_nov here would fail validation regardless of which
        # reference it's on.
        instance_type: instance_types(:comb_et_stat_nov),
        page: "n-plus-one-standalone-#{n}"
      )
    end
    @standalones.each_with_index do |standalone, n|
      Instance.create!(
        namespace: namespaces(:apni),
        created_by: "tester",
        updated_by: "tester",
        reference: @ref,
        name: names(:the_regnum),
        instance_type: instance_types(:nomenclatural_synonym),
        this_is_cited_by: standalone,
        page: "n-plus-one-citing-#{n}"
      )
    end
  end

  test "each standalone instance is paired with its own citing instance" do
    result = Instance::AsArray::ForReference.new(@ref)
    @standalones.each do |standalone|
      citing = result.results.find { |i| i.cited_by_id == standalone.id }
      assert citing, "Expected a citing instance for standalone #{standalone.id}"
    end
  end

  test "instance query count does not scale with the number of standalone instances" do
    query_count = count_instance_load_queries { Instance::AsArray::ForReference.new(@ref) }
    assert_operator query_count, :<, STANDALONE_COUNT,
                     "Expected the number of Instance-table queries to stay well below " \
                     "the number of standalone instances (#{STANDALONE_COUNT}) - got " \
                     "#{query_count}, which suggests a query is again being issued per " \
                     "standalone instance"
  end

  private

  def count_instance_load_queries
    count = 0
    callback = lambda do |*args|
      payload = args.last
      count += 1 if payload[:name] == "Instance Load"
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    count
  end
end
