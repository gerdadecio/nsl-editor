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
class Search::Reference::DefinedQuery
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
              :total

  def initialize(parsed_request, force_list_query = false)
    @parsed_request = parsed_request
    @force_list_query = force_list_query
    run_query
  end

  def run_query
    @has_relation = true
    @rejected_pairings = []
    if @parsed_request.count && !@force_list_query
      run_count_query
    else
      run_list_query
    end
  end

  def run_count_query
    count_query = Search::Reference::DefinedQuery::Count.new(@parsed_request)
    @relation = count_query.sql
    @total = @count = relation.count
    @limited = false
    @info_for_display = count_query.info_for_display
    @common_and_cultivar_included = count_query.common_and_cultivar_included
    @results = []
    @show_csv = false
    @total = nil
  end

  # NOTES (limit/total redesign, follow-up): @count/@total are captured
  # from @references (the plain reference list) rather than @results,
  # and calculated BEFORE consider_instances runs and replaces @results
  # with a reference+instance interleaved array - same fix, and same
  # reason, as Search::OnModel::Base#run_list_query. Not currently
  # reachable through any live search (this class is only ever wrapped
  # by Reference::DefinedQuery::ReferencesNamesFullSynonymy/
  # ReferencesWithNovelties, and neither ever sets show_instances true
  # on the parsed_request they pass through - see
  # Search::ParsedRequest::ALLOW_SHOW_INSTANCES_TARGETS), but kept
  # correct here too rather than leaving a dormant copy of the same bug.
  def run_list_query
    list_query = Search::Reference::DefinedQuery::List.new(@parsed_request)
    @relation = list_query.sql
    @references = relation.all
    @info_for_display = list_query.info_for_display
    @common_and_cultivar_included = list_query.common_and_cultivar_included
    @count = @references.size
    @show_csv = false
    calculate_total
    @limited = @total > @relation.size
    consider_instances
  end

  def consider_instances
    if @parsed_request.show_instances
      show_instances
    else
      @results = @references
    end
  end

  def instances_sort_key
    @parsed_request.order_instances_by_page ? "page" : "name"
  end

  # See Search::OnModel::Base#show_instances for why this batches via
  # preload_for rather than instantiating Instance::AsArray::ForReference
  # (and letting it query) once per reference in @references.
  #
  # NOTES (limit/total redesign): no limit: passed here (was
  # @parsed_request.limit) - same change as Search::OnModel::Base#show_instances,
  # see Instance::AsArray::ForReference's own NOTES for why. instance_offset:
  # is still honoured.
  def show_instances
    sort_key = instances_sort_key
    instances_by_reference, cited_by_map =
      Instance::AsArray::ForReference.preload_for(@references, sort_by: sort_key)

    @results = []
    @references.each do |ref|
      @results << ref
      instances_query = Instance::AsArray::ForReference
                        .new(ref,
                             sort_key,
                             nil,
                             @parsed_request.instance_offset,
                             preloaded_instances: instances_by_reference[ref.id] || [],
                             preloaded_cited_by_map: cited_by_map)
      instances_query.results.each { |i| @results << i }
    end
  end

  def debug(s)
    Rails.logger.debug("Search::Reference::DefinedQuery: #{s}")
  end

  def csv?
    @show_csv
  end

  # NOTES (limit/total redesign): used to special-case show_instances,
  # setting @total = @results.size - since @results is the reference+
  # instances interleaved array, that made @total always equal
  # results.size exactly, so the "N of TOTAL records"/"(limited)" notice
  # in search/search_result_summary/_list could never trigger even when
  # a reference's instance list genuinely was truncated. Now that
  # instance expansion is unlimited (see show_instances/
  # Instance::AsArray::ForReference's NOTES), there's no truncation to
  # hide in the first place, and @total can just be the plain count of
  # matching references in both cases - the same thing
  # Search::OnName::Base#calculate_total does for names.
  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end
end
