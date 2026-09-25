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
class Audit::DefinedQuery::CountQuery
  attr_reader :common_and_cultivar_included,
    :info_for_display,
    :limited,
    :results,
    :sql

  def initialize(parsed_request)
    @parsed_request = parsed_request
    @limited = false
    run_query
    @common_and_cultivar_included = true
    @info_for_display = ""
  end

  def debug(s)
    Rails.logger.debug { "Audit::DefinedQuery::CountQuery - #{s}" }
  end

  def author_query
    start_author_query = Author.all
    author_where_clauses =
      Audit::DefinedQuery::WhereClause::ForAuthor.new(
        @parsed_request,
        start_author_query,
      )
    author_where_clauses.sql
  end

  def name_query
    start_name_query = Name.all
    name_where_clauses =
      Audit::DefinedQuery::WhereClause::ForName.new(
        @parsed_request,
        start_name_query,
      )
    name_where_clauses.sql
  end

  def reference_query
    start_reference_query = Reference.all
    reference_where_clauses =
      Audit::DefinedQuery::WhereClause::ForReference.new(
        @parsed_request,
        start_reference_query,
      )
    reference_where_clauses.sql
  end

  def instance_query
    start_instance_query = Instance.all
    instance_where_clauses =
      Audit::DefinedQuery::WhereClause::ForInstance.new(
        @parsed_request,
        start_instance_query,
      )
    instance_where_clauses.sql
  end

  def run_query
    @results = author_query.to_a +
      name_query.to_a +
      reference_query.to_a +
      instance_query.to_a
  end
end
