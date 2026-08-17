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

# Instances are associated with a Name as:
# - standalone instances for the Name, or as
# - relationship instances that cite or are cited by those standalones.
#
# This class collects the instances associated with a single name
# in the accepted order and sets the display attributes for each record.
#
# The collection is in the results attribute.
#
# e.g.
# name = [find some name]
# instances = Instance::AsArray::ForName.new(name)
# puts instances.results.size
#
# NOTES (N+1 fix, structural): a caller expanding instances for MANY names
# at once (e.g. Search::OnName::WithInstances, once per matching name of a
# show-instances: name search) used to instantiate this class once per
# name, and each instance ran its own queries - the name's own instance
# list, plus one further query per standalone instance it found
# (records_cited_by_standalone) and one further query per distinct citing
# instance behind any relationship instance it found
# (records_cited_by_relationship). So query count scaled with the number
# of matching names AND the instances within each - confirmed in practice:
# a 400-name show-instances: search took ~45s. preload_for batches all
# three of those per-name queries across every name given, in three
# queries total, however many names there are - the same fix already
# applied to Reference plus Instance searches, see
# Instance::AsArray::ForReference.preload_for. Callers that already have
# several names to expand should call .preload_for once, then pass its
# three return values into .new via preloaded_instances:/
# preloaded_standalone_cited_by_map:/preloaded_relationship_cited_by_map:
# for each one, so only the three batched queries run, not up to three per
# name. A caller with just one name (or that hasn't been updated, e.g.
# Search::OnName::WithInstancesToCopy) can keep calling .new the old way -
# it falls back to running its own queries exactly as before.
#
# NOTES (round 2, from a dev-log review of a real 400-name search):
# batching the three queries above still left three further N+1s exposed
# once enough names/instances actually flowed through them - none
# introduced here, all pre-existing, just newly visible at this volume:
# instance.this_is_cited_by and instance.profile_items (via
# draft_for_sorting?, called from sort_fields) weren't in the base
# includes, and the cited_by-map queries never preloaded :name despite
# relationship_instance_records comparing cited_by_original_instance.name.id
# against the search name's id row by row. All three are now covered by
# includes above/below. sorted_instances was also switched from a
# block-based .sort (which calls its comparator, and so sort_fields,
# roughly n*log(n) times) to .sort_by (exactly once per instance) - see
# its own NOTES.
class Instance::AsArray::ForName < Array
  attr_reader :results

  NO_YEAR = ""

  class << self
    # Batches the three queries this class would otherwise run once per
    # name / once per standalone or relationship instance found within
    # those names. Returns [instances_by_name_id,
    # standalone_cited_by_map, relationship_cited_by_map] - pass all
    # three into .new (see preloaded_instances:/
    # preloaded_standalone_cited_by_map:/
    # preloaded_relationship_cited_by_map: above) for every name in
    # `names`.
    def preload_for(names)
      name_ids = names.map(&:id)
      return [{}, {}, {}] if name_ids.empty?

      instances = Instance.where(name_id: name_ids)
                           .includes([{ reference: :author }, :instance_type,
                                      :this_is_cited_by, :profile_items])
                           .to_a
      instances_by_name = instances.group_by(&:name_id)

      standalone_ids = instances.select(&:standalone?).map(&:id)
      # A relationship instance's "citing instance" (this_is_cited_by) is
      # not necessarily one of the standalone instances just fetched above
      # - it may belong to a different name entirely (e.g. the standalone
      # instance of the accepted name that a misapplication/synonym in
      # `names` is cited by), so it's collected separately here rather
      # than reused from standalone_ids.
      citing_ids = instances.reject(&:standalone?).map(&:cited_by_id).uniq

      [instances_by_name,
       standalone_cited_by_map_for(standalone_ids),
       relationship_cited_by_map_for(citing_ids)]
    end

    # Same query show_standalone_instance's records_cited_by_standalone
    # ran once per standalone instance, batched across every standalone
    # id given - the query doesn't depend on anything about a specific
    # standalone instance beyond its id, so grouping a single query's
    # results by cited_by_id reproduces the same per-instance result and
    # order a per-instance query would have.
    def standalone_cited_by_map_for(standalone_ids)
      return {} if standalone_ids.empty?

      Instance.joins(:instance_type, :name, :reference)
              .joins("left outer join instance cites on instance.cites_id = cites.id")
              .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
              .joins("inner join name_status ns on name.name_status_id = ns.id")
              .includes(:instance_type, name: :name_status)
              .where(cited_by_id: standalone_ids)
              .in_synonymy_order
              .order("reference.iso_publication_date,lower(name.full_name)")
              .to_a
              .group_by(&:cited_by_id)
    end

    # Same query show_relationship_instance's records_cited_by_relationship
    # ran once per distinct citing instance, batched across every citing
    # id given - same reasoning as standalone_cited_by_map_for above.
    # Deliberately kept as a separate query/map from
    # standalone_cited_by_map_for even though both look for "everything
    # cited by id X": records_cited_by_relationship doesn't apply the
    # secondary reference.iso_publication_date/name.full_name order the
    # standalone query does, and merging them would change relationship
    # instance ordering.
    def relationship_cited_by_map_for(citing_ids)
      return {} if citing_ids.empty?

      Instance.joins(:instance_type, :name, :reference)
              .joins("left outer join instance cites on instance.cites_id = cites.id")
              .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
              .joins("inner join name_status ns on name.name_status_id = ns.id")
              .includes(:instance_type, name: :name_status)
              .where(cited_by_id: citing_ids)
              .in_synonymy_order
              .to_a
              .group_by(&:cited_by_id)
    end
  end

  def initialize(name, preloaded_instances: nil,
                 preloaded_standalone_cited_by_map: nil,
                 preloaded_relationship_cited_by_map: nil)
    @results = []
    @already_shown = []
    @preloaded_standalone_cited_by_map = preloaded_standalone_cited_by_map
    @preloaded_relationship_cited_by_map = preloaded_relationship_cited_by_map
    instances = preloaded_instances || name.instances.includes([{ reference: :author }, :instance_type,
                                                                  :this_is_cited_by, :profile_items])
    sorted_instances(instances).each do |instance|
      if instance.standalone?
        show_standalone_instance(instance)
      else
        show_relationship_instance(name, instance)
      end
    end
  end

  def debug(s)
    Rails.logger.debug("Instance::AsArray::ForName: #{s}")
  end

  # NOTES (perf): was `.sort { |i1, i2| sort_fields(i1) <=> sort_fields(i2) }`
  # - a block-based sort calls its comparator roughly n*log(n) times, so
  # sort_fields (and everything it touches, e.g. draft_for_sorting?'s
  # profile_items lookup) ran that many times per instance instead of
  # once. sort_by computes each instance's sort key exactly once
  # (Schwartzian transform), which matters even with profile_items now
  # preloaded - it's real Ruby method-call overhead either way.
  def sorted_instances(instances)
    instances.to_a.sort_by { |instance| sort_fields(instance) }
  end

  # Sort order:
  # 1. Draft status (non-drafts before drafts)
  # 2. Whether instance has a year (dated before undated within same draft group)
  # 3. Year (chronologically, earliest first)
  # 4. Primary instance type first
  # 5. ISO publication date
  # 6. Author name (alphabetically)
  #
  # This ensures undated instances stay within their draft/non-draft group:
  # - Undated non-draft instances sort immediately after dated non-drafts
  # - Undated draft instances sort immediately after dated drafts
  # - draft instances are instance.draft? or profile_item.draft?
  def sort_fields(instance)
    ref = instance.reference
    year = ref.year || parent_attr(ref, :year)
    iso_date = ref.iso_publication_date || parent_attr(ref, :iso_publication_date)

    [
      draft_sort_order(instance),             # "A" (non-draft) or "B" (draft)
      dated_first(year),                      # 0 (has year) or 1 (no year)
      year || NO_YEAR,                        # 2026 or ""
      instance.instance_type.primaries_first, # "A" (primary instance) or "B" (non-primary)
      iso_date || NO_YEAR,                    # "2026-01-01" or ""
      author_name(instance).downcase          # "authorname, g." or "x" (if nil)
    ]
  end

  # NOTES: Handle references that inherit publication metadata from a parent reference in the hierarchy.
  def parent_attr(reference, attribute)
    reference.try(:parent).try(attribute)
  end

  def dated_first(year)
    year.present? ? 0 : 1
  end

  # NOTES: Non-drafts sort before drafts (A < B)
  # Replaced the instance.draft? with instance.draft_for_sorting?
  # (so we don't change the existing instance.draft? logic, which maybe used elsewhere in the codebase)
  def draft_sort_order(instance)
    instance.draft_for_sorting? ? "B" : "A"
  end

  def author_name(instance)
    instance.reference.author.try("name") || "x"
  end

  def show_standalone_instance(instance)
    debug("show_standalone_instance #{instance.id}")
    standalone_instance_records(instance).each do |one_instance|
      one_instance.show_primary_instance_type = true
      one_instance.consider_taxo = true
      @results.push(one_instance)
    end
  end

  # Work on a single standalone instance starts here.
  # - display the instance as part of a concept
  # - find all child instances using the cited_by_id column
  #   (all instances that say they are cited by the standalone instance)
  #   - display these relationship instances as cited_by the standalone instance
  def standalone_instance_records(instance)
    debug("show_standalone_instance_records #{instance.id}")
    results = [instance.display_as_part_of_concept]
    records_cited_by_standalone(instance)
      .each do |cited_by_original_instance|
        cited_by_original_instance.expanded_instance_type =
          cited_by_original_instance.instance_type.name
        cited_by_original_instance.display_as = "instance-is-cited-by"
        results.push(cited_by_original_instance)
      end
    results
  end

  # Only used when no preloaded_standalone_cited_by_map: was given to .new.
  def records_cited_by_standalone(instance)
    debug("records_cited_by_standalone for instance #{instance.id}")
    @preloaded_standalone_cited_by_map&.fetch(instance.id, []) ||
      self.class.standalone_cited_by_map_for([instance.id]).fetch(instance.id, [])
  end

  def show_relationship_instance(name, instance)
    citing_instance = instance.this_is_cited_by
    return if @already_shown.include?(citing_instance.id)

    relationship_instance_records(name, citing_instance).each do |element|
      element.consider_taxo = false
      @results.push(element)
    end
    @already_shown.push(citing_instance.id)
  end

  # NSL-536: If instance name is not the subject name then
  # do not show the instance type.
  def relationship_instance_records(name, instance)
    results = [instance.display_as_citing_instance_within_name_search]
    records_cited_by_relationship(instance)
      .each do |cited_by_original_instance|
      next unless cited_by_original_instance.name.id == name.id

      cited_by_original_instance.expanded_instance_type =
        cited_by_original_instance.instance_type.name
      results.push(with_display_as(cited_by_original_instance))
    end
    results
  end

  def with_display_as(instance)
    debug("with_display_as for instance #{instance.id}")
    instance.display_as = if instance.misapplied?
                            "cited-by-relationship-instance"
                          else
                            "cited-by-relationship-instance-name-only"
                          end
    instance
  end

  # Only used when no preloaded_relationship_cited_by_map: was given to .new.
  def records_cited_by_relationship(instance)
    debug("records_cited_by_relationship for instance #{instance.id}")
    @preloaded_relationship_cited_by_map&.fetch(instance.id, []) ||
      self.class.relationship_cited_by_map_for([instance.id]).fetch(instance.id, [])
  end
end
