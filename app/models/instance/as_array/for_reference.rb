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

# Instances are associated with a Reference as:
# - standalone instances for the Reference, or as
# - relationship instances that cite or are cited by those standalones.
#
# This class collects the instances associated with a single reference
# in the accepted order and sets the display attributes for each record.
#
# The collection is in the results attribute.
#
# e.g.
# reference = [find some reference]
# instances = Instance::AsArray::ForReference.new(reference)
# puts instances.results.size
#
# NOTES (N+1 fix, structural): a caller expanding instances for MANY
# references at once (e.g. Search::OnModel::Base#show_instances, once per
# matching reference of a show-instances: search) used to instantiate this
# class once per reference, and each instance ran its own queries - so
# query count scaled with the number of matching references, even after
# the earlier fix that stopped it scaling with the number of instances
# within a single reference. Instance::AsArray::ForReference.preload_for
# batches both of those per-reference queries (the reference's own
# instance list, and the is-cited-by lookup for its standalone instances)
# across every given reference in two queries total, however many
# references there are. Callers that already have several references to
# expand should call .preload_for once, then pass its two return values
# into .new via preloaded_instances:/preloaded_cited_by_map: for each one,
# so only the two batched queries run, not two per reference. A caller
# with just one reference (or that hasn't been updated) can keep calling
# .new the old way - it falls back to running its own queries exactly as
# before.
class Instance::AsArray::ForReference < Array
  attr_reader :results

  class << self
    # Batches the two queries find_instances_for_ref would otherwise run
    # once per reference. Returns [instances_by_reference_id,
    # cited_by_map] - pass both into .new (see preloaded_instances:/
    # preloaded_cited_by_map: above) for every reference in `references`.
    def preload_for(references, sort_by: "name")
      reference_ids = references.map(&:id)
      return [{}, {}] if reference_ids.empty?

      instances = base_query(sort_by).where(reference_id: reference_ids).to_a
      instances_by_reference = instances.group_by(&:reference_id)

      standalone_ids = instances.select { |instance| instance.cited_by_id.blank? }.map(&:id)
      [instances_by_reference, cited_by_map_for(standalone_ids)]
    end

    def base_query(sort_by)
      query = Instance
              .joins(:name)
              .includes(name: :name_status)
              .includes(:instance_type)
              .includes(this_is_cited_by: %i[name instance_type])
      sort_by == "page" ? query.ordered_by_page : query.ordered_by_name
    end

    # See the find_instances_for_ref note (below, instance-level) for why
    # this batches cleanly: the query doesn't depend on anything about a
    # specific standalone instance beyond its id, so it can run once for
    # every standalone id given - whether that's every standalone instance
    # on one reference, or on a hundred of them - and still produce, once
    # grouped by cited_by_id, the same per-instance result and order a
    # per-instance query would have.
    def cited_by_map_for(standalone_ids)
      return {} if standalone_ids.empty?

      cited_by_instances = Instance.where(cited_by_id: standalone_ids)
                                    .joins(:instance_type, :name)
                                    .joins("inner join name_status ns on name.name_status_id = ns.id")
                                    .joins("left outer join instance cites on instance.cites_id = cites.id")
                                    .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
                                    .includes(:instance_type, :name)
                                    .in_synonymy_order
                                    .to_a
      cited_by_instances.each { |instance| instance.display_as = "cited-by-instance" }
      cited_by_instances.group_by(&:cited_by_id)
    end
  end

  def initialize(reference, sort_by = "name", limit = 1000, offset = 0,
                 preloaded_instances: nil, preloaded_cited_by_map: nil)
    debug("init #{reference.citation}")
    @results = []
    @already_shown = []
    @reference = reference
    @count = 0
    @limit = limit
    @sort_by = sort_by
    @offset = offset || 0
    @limit += @offset if @limit < @offset
    @preloaded_instances = preloaded_instances
    @preloaded_cited_by_map = preloaded_cited_by_map
    find_instances
  end

  def debug(s)
    Rails.logger.debug("Instance::AsArray::ForReference: #{s}")
  end

  def find_instances
    debug "find_instances"
    @reference.display_as_part_of_concept
    @count = 1
    find_instances_for_ref
    @limited = true if @count > @limit
    @results
  end

  # Only used when no preloaded_instances: was given to .new - a single
  # reference queried on its own, same query preload_for's base_query runs
  # for many references at once, just scoped down to this one.
  def built_query
    self.class.base_query(@sort_by).where(reference_id: @reference.id)
  end

  def find_instances_for_ref
    instances = @preloaded_instances || built_query.to_a
    @cited_by_map = @preloaded_cited_by_map || fetch_cited_by_map(instances)

    instances.each do |instance|
      if instance.cited_by_id.blank?
        if @count < @offset
          @count += 1
        elsif @count < @limit
          @count += 1
          include_standalone_instance_and_synonymy(instance)
          include_synonym(instance) unless instance.cites_this.nil?
        end
      end
      break if @count > @limit
    end
  end

  # Only used when no preloaded_cited_by_map: was given to .new.
  def fetch_cited_by_map(instances)
    standalone_ids = instances.select { |instance| instance.cited_by_id.blank? }.map(&:id)
    self.class.cited_by_map_for(standalone_ids)
  end

  def include_standalone_instance_and_synonymy(instance)
    instance.display_within_reference
    @results.push(instance)
    @cited_by_map.fetch(instance.id, []).each do |cited_by|
      @count += 1
      cited_by.expanded_instance_type = cited_by.instance_type.name
      @results.push(cited_by)
    end
  end

  def include_synonym(instance)
    @results.push(instance.cites_this)
    @count += 1
  end
end
