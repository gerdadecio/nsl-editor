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
class Instance::AsArray::ForReference < Array
  attr_reader :results

  def initialize(reference, sort_by = "name", limit = 1000, offset = 0)
    debug("init #{reference.citation}")
    @results = []
    @already_shown = []
    @reference = reference
    @count = 0
    @limit = limit
    @sort_by = sort_by
    @offset = offset || 0
    @limit += @offset if @limit < @offset
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

  def built_query
    query = @reference
            .instances
            .joins(:name)
            .includes(name: :name_status)
            .includes(:instance_type)
            .includes(this_is_cited_by: %i[name instance_type])
    @sort_by == "page" ? query.ordered_by_page : query.ordered_by_name
  end

  # NOTES (N+1 fix): this used to call instance.is_cited_by once per
  # standalone instance below, in include_standalone_instance_and_synonymy -
  # each call its own query with 4 joins and a raw-SQL synonymy sort. A
  # reference with many standalone instances (or a search expanding many
  # such references at once, e.g. show-instances:) turned that into one
  # extra query per standalone instance, which measured as several extra
  # seconds on broad searches.
  #
  # is_cited_by's query doesn't depend on anything about the specific
  # standalone instance beyond its id, so it batches cleanly: materialize
  # built_query once (rather than streaming it via #each), then fetch
  # every instance citing ANY of this reference's standalone instances in
  # a single query (fetch_cited_by_map, keyed by cited_by_id) before the
  # main loop runs. The ORDER BY in that query doesn't reference
  # cited_by_id at all, so grouping the combined, sorted result set by
  # cited_by_id afterwards gives each group the same relative order it
  # would have had if queried individually - this is purely a batching
  # change, not a change to what gets returned or how it's ordered.
  def find_instances_for_ref
    instances = built_query.to_a
    @cited_by_map = fetch_cited_by_map(instances)

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

  # See the find_instances_for_ref note above - this replaces what used to
  # be a per-instance call to instance.is_cited_by with a single query
  # covering every standalone instance in `instances`, grouped by
  # cited_by_id so include_standalone_instance_and_synonymy can look its
  # own instance up in memory instead of querying again.
  def fetch_cited_by_map(instances)
    standalone_ids = instances.select { |instance| instance.cited_by_id.blank? }.map(&:id)
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
