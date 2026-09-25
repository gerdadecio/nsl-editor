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
class Audit::DefinedQuery::WhereClause::ForReference
  attr_reader :sql

  def initialize(parsed_request, incoming_sql)
    debug("initialize")
    @parsed_request = parsed_request
    @sql = incoming_sql
    build_sql
  end

  def build_sql
    debug("#build_sql")
    remaining_string = @parsed_request.where_arguments.downcase
    @common_and_cultivar_included = @parsed_request.common_and_cultivar
    @sql = @sql.for_id(@parsed_request.id) if @parsed_request.id
    @sql = Audit::DefinedQuery::WhereClause::Authorise
      .new(sql, @parsed_request.user).sql
    x = 0
    until remaining_string.blank?
      debug("loop for remaining_string: #{remaining_string}")
      field, value, remaining_string = Search::NextCriterion
        .new(remaining_string).get
      debug("field: #{field}; value: #{value}")
      @sql = Audit::DefinedQuery::WhereClause::Predicate
        .new(sql, field, value, "reference").sql
      x += 1
      raise "endless loop #{x}" if x > 50
    end
  end

  def debug(s)
    Rails.logger.debug { "Audit::DefinedQuery::WhereClause::ForReference #{s}" }
  end
end
