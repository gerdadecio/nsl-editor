# frozen_string_literal: true

# Names can be in a classification tree
module Instance::Treeable
  extend ActiveSupport::Concern

  class_methods do
    # NOTES (N+1 fix): in_published_trees below used to be called once per
    # instance from app/views/instances/taxo/_widgets.html.erb - each call
    # its own 3-join query - so a search results page listing hundreds of
    # instances (e.g. a reference search with show-instances:) fired
    # hundreds of these queries. Confirmed via the development log as the
    # single largest source of query time on a slow "ang si:" search (707ms
    # across 394 queries - more than every other query type combined).
    #
    # This batches the same query across every instance id given, grouped
    # by instance id, so a whole page of results can be looked up with one
    # query instead of one per row. in_published_trees itself now just
    # calls this for a single id, so both stay in sync with one query
    # definition.
    def published_trees_map_for(instances_or_ids)
      ids = Array.wrap(instances_or_ids)
                 .map { |i| i.respond_to?(:id) ? i.id : i }
                 .compact.uniq
      return {} if ids.empty?

      Instance
        .joins('INNER JOIN tree_element ON instance.id = tree_element.instance_id')
        .joins('JOIN tree_version_element tve ON tree_element.id = tve.tree_element_id')
        .joins('JOIN tree t ON tve.tree_version_id = t.current_tree_version_id')
        .where(id: ids)
        .where('t.is_read_only = false')
        .select('instance.id, t.name AS tree_name, tree_element.excluded AS excluded')
        .group_by(&:id)
    end
  end

  def accepted_tree_version_element
    Tree.accepted.first.current_tree_version.instance_in_version(self)
  end

  def default_draft_tree_version_element
    Tree.accepted.first.default_draft_version.instance_in_version(self)
  end

  def accepted_concept?
    tve = accepted_tree_version_element
    tve.present? && !tve.tree_element.excluded
  end

  def excluded_concept?
    return nil unless accepted_concept?

    accepted_tree_version_element.tree_element.excluded
  end

  def in_any_tree?
    ::Tree::Element.where(instance_id: id).count > 0
  end

  def show_taxo?
    id == name.accepted_instance_id
  end

  def in_published_trees
    self.class.published_trees_map_for(id).fetch(id, [])
  end

  def in_workspace?(workspace)
    id == name.draft_instance_id(workspace)
  end

  def in_local_trees?
    in_local_trees.any?
  end

  def in_local_trees
    Tree.find_by_sql(["select t.* from tree_version_element tve join tree t on t.current_tree_version_id = tve.tree_version_id
  join tree_element te on tve.tree_element_id = te.id
where te.instance_id = ?", id])
  end

  def in_any_local_tree_ids?(tree_ids)
    return false if tree_ids.blank?

    Tree.joins("JOIN tree_version_element tve ON tree.current_tree_version_id = tve.tree_version_id")
        .joins("JOIN tree_element te ON tve.tree_element_id = te.id")
        .where(id: tree_ids)
        .where("te.instance_id = ?", id)
        .exists?
  end

  def in_local_tree_names
    in_local_trees.collect do |tree|
      tree.name
    end.join(", ")
  end
end
