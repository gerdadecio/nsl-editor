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
# NOTES (N+1 fix, structural): see the equivalent note on
# Instance::AsArray::ForReference - a caller expanding novelties for many
# references at once (Search::OnModel::Base#show_novelties) used to
# instantiate this class once per reference, each running its own query.
# .preload_for batches that into one query for every given reference, to
# be passed into .new via preloaded_instances:. A caller with just one
# reference (or that hasn't been updated) can keep calling .new the old
# way - it falls back to running its own query exactly as before.
class Instance::AsArray::ForReference::ForNovelties < Array
  attr_reader :results

  class << self
    def preload_for(references, sort_by: "name")
      reference_ids = references.map(&:id)
      return {} if reference_ids.empty?

      base_query(sort_by).where(reference_id: reference_ids).to_a.group_by(&:reference_id)
    end

    def base_query(sort_by)
      query = Instance
              .joins(:name)
              .includes(name: :name_status)
              .joins(:instance_type)
              .where(instance_type: { primary_instance: true })
              .includes(this_is_cited_by: %i[name instance_type])
      sort_by == "page" ? query.ordered_by_page : query.ordered_by_name
    end
  end

  def initialize(reference, sort_by = "name", limit = 1000, offset = 0,
                 preloaded_instances: nil)
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

  # Only used when no preloaded_instances: was given to .new.
  def built_query
    self.class.base_query(@sort_by).where(reference_id: @reference.id)
  end

  def find_instances_for_ref
    instances = @preloaded_instances || built_query.to_a
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

  def include_standalone_instance_and_synonymy(instance)
    instance.display_within_reference
    @results.push(instance)
    #instance.is_cited_by
    #        .each do |cited_by|
    #  @count += 1
    #  cited_by.expanded_instance_type = cited_by.instance_type.name
    #  @results.push(cited_by)
    #end
  end

  def include_synonym(instance)
    @results.push(instance.cites_this)
    @count += 1
  end
end
