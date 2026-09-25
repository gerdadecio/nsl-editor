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
class Audit::DefinedQuery::ListQuery
  attr_reader :common_and_cultivar_included,
    :info_for_display,
    :limited,
    :results,
    :sql

  def initialize(parsed_request)
    @parsed_request = parsed_request
    assemble_results
    @common_and_cultivar_included = true
    @info_for_display = ""
  end

  def debug(s)
    Rails.logger.debug { "Audit::DefinedQuery::ListQuery - #{s}" }
  end

  def assemble_results
    Rails.logger.debug("Audit::DefinedQuery::ListQuery#assemble_results")
    results = query_results
    results = sort_results(results)
    @results = results[0..@parsed_request.limit - 1]
    @limited = results.size > @results.size
  end

  def query_results
    author_query.to_a +
      name_query.to_a +
      reference_query.to_a +
      instance_query.to_a
  end

  def sort_results(results)
    results.sort do |x, y|
      bigger(y.created_at, y.updated_at) <=> bigger(x.created_at, x.updated_at)
    end
  end

  def author_query
    start_author_query = Author.limit(@parsed_request.limit)
    author_where_clauses =
      Audit::DefinedQuery::WhereClause::ForAuthor.new(
        @parsed_request,
        start_author_query,
      )
    author_where_clauses.sql
  end

  def name_query
    start_name_query = Name.limit(@parsed_request.limit)
    name_where_clauses =
      Audit::DefinedQuery::WhereClause::ForName.new(
        @parsed_request,
        start_name_query,
      )
    name_where_clauses.sql
  end

  def reference_query
    start_reference_query = Reference.limit(@parsed_request.limit)
    reference_where_clauses =
      Audit::DefinedQuery::WhereClause::ForReference.new(
        @parsed_request,
        start_reference_query,
      )
    reference_where_clauses.sql
  end

  def instance_query
    start_instance_query = Instance.limit(@parsed_request.limit)
    instance_where_clauses =
      Audit::DefinedQuery::WhereClause::ForInstance.new(
        @parsed_request,
        start_instance_query,
      )
    instance_where_clauses.sql
  end

  def bigger(first, second)
    first > second ? first : second
  end
end
