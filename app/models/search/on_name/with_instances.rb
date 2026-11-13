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

# Core search class for Name search
#
# You can run this in the console, once you have a parsed request:
#
# search = Search::OnName::Base.new(parsed_request)
#
# NOTES (N+1 fix, structural): used to instantiate a fresh
# Instance::AsArray::ForName per matching name, each running its own
# queries - so query count scaled with the number of matching names (and,
# within each, its own instances). preload_for batches those per-name
# queries across every name in `names` up front, so each
# Instance::AsArray::ForName built below does no queries of its own - it's
# just replaying already-fetched data through the same
# counting/expansion logic as before. Same fix already applied to
# Reference plus Instance searches - see
# Search::OnModel::Base#show_instances.
#
# With tree_instances_only: true (NSL-6048, the show-tree-instances:
# directive), each name shows only the instance used for it in the current
# version of the accepted tree, with that instance's synonymy. A name that
# isn't on the accepted tree shows no instances.
class Search::OnName::WithInstances
  attr_reader :names_with_instances

  def initialize(names, tree_instances_only: false)
    instances_by_name, standalone_cited_by_map, relationship_cited_by_map =
      Instance::AsArray::ForName.preload_for(names)
    instances_by_name = only_tree_instances(names, instances_by_name) if tree_instances_only

    results = []
    names.each do |name|
      name.display_as_part_of_concept
      results << name
      Instance::AsArray::ForName.new(
        name,
        preloaded_instances: instances_by_name[name.id] || [],
        preloaded_standalone_cited_by_map: standalone_cited_by_map,
        preloaded_relationship_cited_by_map: relationship_cited_by_map,
      ).results.each do |usage_rec|
        results << usage_rec
      end
    end
    @names_with_instances = results
  end

  private

  def only_tree_instances(names, instances_by_name)
    tree_instance_ids = accepted_tree_instance_ids(names.map(&:id))
    instances_by_name.transform_values do |instances|
      instances.select { |instance| tree_instance_ids.include?(instance.id) }
    end
  end

  # The instance each name has in the current version of the accepted tree.
  def accepted_tree_instance_ids(name_ids)
    tree_version_id = Tree.accepted.first&.current_tree_version_id
    return Set.new if tree_version_id.nil? || name_ids.empty?

    TreeVersionElement.joins(:tree_element)
      .where(tree_version_id: tree_version_id, tree_element: { name_id: name_ids })
      .pluck("tree_element.instance_id")
      .to_set
  end
end
