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
    :do_count_totals,
    :instance_row_count

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
    # NOTES (limit/total redesign, follow-up): @count/@total must be
    # captured here, from the plain reference (or author/batch/etc.)
    # result set - BEFORE consider_instances/consider_novelties replace
    # @results with a reference+instance (or reference+novelty)
    # interleaved array. Reported in user testing: a References search
    # "pl si: limit: 600" showed "4443 of 6755 records" - 4443 was
    # @results.size AFTER instance expansion (references+instances
    # combined), 6755 was the reference-only total from calculate_total,
    # so the numerator and denominator were counting different things.
    # @count now always means "how many References this search matched
    # (within the limit)", same as Search::OnName::Base uses @names.size
    # rather than @results.size for its own count/summary.
    if @do_count_totals
      @count = @results.size
      calculate_total
    else
      @count = @total = 0
    end
    consider_instances(parsed_request)
    consider_novelties(parsed_request)
    consider_loader_name_extras(parsed_request)
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
  # references. The instances are now preloaded for every reference in
  # @results up front - see Search::Reference::InstanceExpansion.
  #
  # NOTES (NSL-6001): instance-limit: (default 1000) caps the standalone
  # instances shown per reference, and instance_row_count counts the
  # instance rows shown, separately from the reference count.
  def show_instances(parsed_request)
    expansion = Search::Reference::InstanceExpansion.new(@results, parsed_request)
    @results = expansion.results
    @instance_row_count = expansion.instance_row_count
  end

  # See the show_instances note above - same, applied to novelties.
  def show_novelties(parsed_request)
    expansion = Search::Reference::InstanceExpansion.new(@results, parsed_request, novelties: true)
    @results = expansion.results
    @instance_row_count = expansion.instance_row_count
  end

  def consider_loader_name_extras(parsed_request)
    return unless parsed_request.target_model == "Loader::Name"
    return unless parsed_request.print

    show_comments = parsed_request.show_loader_name_comments
    @results = Search::Loader::Name::RewriteResultsShowingExtras
      .new(@results, show_comments).rewrite_results
  end

  def debug(s)
    Rails.logger.debug { "Search::OnModel::Base: #{s}" }
  end

  def csv?
    @show_csv
  end

  def calculate_total
    @total = @relation.except(:offset, :limit, :order).count
  end
end
