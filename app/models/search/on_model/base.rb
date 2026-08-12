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
# Search a Model
class Search::OnModel::Base
  attr_reader :results,
              :limited,
              :info_for_display,
              :rejected_pairings,
              :common_and_cultivar_included,
              :has_relation,
              :relation,
              :id,
              :count,
              :show_csv,
              :total,
              :limit,
              :do_count_totals

  def initialize(parsed_request)
    run_query(parsed_request)
  end

  def run_query(parsed_request)
    @has_relation = true
    @show_csv = false
    @rejected_pairings = []
    @do_count_totals = true
    if parsed_request.count
      run_count_query(parsed_request)
    else
      run_list_query(parsed_request)
      @limit = parsed_request.limit
    end
  end

  def run_count_query(parsed_request)
    count_query = Search::OnModel::CountQuery.new(parsed_request)
    @relation = count_query.sql
    @count = @relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @total = nil
  end

  def run_list_query(parsed_request)
    list_query = Search::OnModel::ListQuery.new(parsed_request)
    @relation = list_query.sql
    @results = @relation.all
    @results = list_query.trim_results(@results)
    @limited = list_query.limited
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @do_count_totals = list_query.do_count_totals
    consider_instances(parsed_request)
    consider_novelties(parsed_request)
    consider_loader_name_extras(parsed_request)
    if @do_count_totals
      @count = @results.size
      calculate_total
    else
      @count = @total = 0
    end
  end

  def consider_instances(parsed_request)
    return unless parsed_request.show_instances

    show_instances(parsed_request)
  end

  def consider_novelties(parsed_request)
    return unless parsed_request.show_novelties

    show_novelties(parsed_request)
  end

  # NOTES (N+1 fix, structural): used to instantiate a fresh
  # Instance::AsArray::ForReference per matching reference, each running
  # its own queries - so query count scaled with the number of matching
  # references (confirmed via the dev log: ~135 references, ~135 extra
  # queries, on a broad show-instances: search). preload_for batches the
  # per-reference queries across every reference in @results up front, so
  # each Instance::AsArray::ForReference built below does no queries of
  # its own - it's just replaying already-fetched data through the same
  # counting/expansion logic as before.
  def show_instances(parsed_request)
    sort_key = instances_sort_key(parsed_request)
    instances_by_reference, cited_by_map =
      Instance::AsArray::ForReference.preload_for(@results, sort_by: sort_key)

    results_with_instances = []
    @results.each do |ref|
      results_with_instances << ref
      instances_query = Instance::AsArray::ForReference
                        .new(ref,
                             sort_key,
                             parsed_request.limit,
                             parsed_request.instance_offset,
                             preloaded_instances: instances_by_reference[ref.id] || [],
                             preloaded_cited_by_map: cited_by_map)
      instances_query.results.each { |i| results_with_instances << i }
    end
    @results = results_with_instances
  end

  def instances_sort_key(parsed_request)
    parsed_request.order_instances_by_page ? "page" : "name"
  end

  # See the show_instances note above - same fix, applied to novelties.
  def show_novelties(parsed_request)
    sort_key = novelties_sort_key(parsed_request)
    instances_by_reference =
      Instance::AsArray::ForReference::ForNovelties.preload_for(@results, sort_by: sort_key)

    results_with_instances = []
    @results.each do |ref|
      results_with_instances << ref
      instances_query = Instance::AsArray::ForReference::ForNovelties
                        .new(ref,
                             sort_key,
                             parsed_request.limit,
                             parsed_request.instance_offset,
                             preloaded_instances: instances_by_reference[ref.id] || [])
      instances_query.results.each { |i| results_with_instances << i }
    end
    @results = results_with_instances
  end

  def novelties_sort_key(parsed_request)
    parsed_request.order_novelties_by_page ? "page" : "name"
  end

  def consider_loader_name_extras(parsed_request)
    return unless parsed_request.target_model == "Loader::Name"
    return unless parsed_request.print

    show_comments = parsed_request.show_loader_name_comments
    @results = Search::Loader::Name::RewriteResultsShowingExtras
               .new(@results, show_comments).rewrite_results
  end

  def debug(s)
    Rails.logger.debug("Search::OnModel::Base: #{s}")
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end
end
