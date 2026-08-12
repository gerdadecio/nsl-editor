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

# Regression test for the N+1 fix to instances/taxo/_widgets.html.erb: the
# controller should pre-compute @published_trees_map for the whole page of
# results (see SearchController#prepare_published_trees_map and
# Instance.published_trees_map_for) so InstancesHelper#published_trees_for
# can look each instance up in memory instead of querying per row.
class SearchRefsOnIdPopulatesPublishedTreesMapTest < ActionController::TestCase
  tests SearchController

  test "populates @published_trees_map with a Hash for a show-instances search" do
    ref = references(:bucket_reference_for_default_instances)
    get(:search,
        params: { query_target: "reference",
                  query_string: "id: #{ref.id} show-instances:" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_kind_of Hash, assigns(:published_trees_map),
                    "Expected @published_trees_map to be populated as a Hash"
  end

  test "populates @published_trees_map with an empty Hash when no instances are in the results" do
    get(:search,
        params: { query_target: "reference",
                  query_string: "id: #{references(:bucket_reference_for_default_instances).id}" },
        session: { username: "fred",
                   user_full_name: "Fred Jones",
                   groups: [] })
    assert_response :success
    assert_equal({}, assigns(:published_trees_map))
  end
end
