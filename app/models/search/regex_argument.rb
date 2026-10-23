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
#   Prepares the argument of a search directive whose rule is marked
#   regex: true, i.e. the argument is a Postgres regular expression (NSL-6004).
#
#   - Asterisks are left alone: "*" is a regex quantifier, so the usual
#     "*" to "%" wildcard conversion would break patterns such as ".*".
#   - A bare "*" is what users type when they mean "has any value", but on
#     its own it is not a valid regex, so it becomes "." and a note says so.
#   - Any other pattern is checked with Postgres itself (its regex dialect
#     differs from Ruby's), so an invalid one gets an error naming the
#     directive instead of the generic "That query did not work".
class Search::RegexArgument
  BARE_ASTERISK = "*"
  ANY_VALUE = "."

  attr_reader :value, :note

  def initialize(directive, value)
    @directive = directive
    @value = value
    @note = nil
    return if @value.blank?

    treat_bare_asterisk_as_any_value
    check_pattern_is_valid
  end

  private

  def treat_bare_asterisk_as_any_value
    return unless @value.strip == BARE_ASTERISK

    @value = ANY_VALUE
    @note = %(#{@directive} takes a regular expression, so "*" was treated as "has any value" (".").)
  end

  # The savepoint keeps a failed check from aborting an enclosing transaction.
  def check_pattern_is_valid
    ActiveRecord::Base.transaction(requires_new: true) do
      ActiveRecord::Base.connection.select_value(
        ActiveRecord::Base.sanitize_sql_array([ "select '' ~ ?", @value ]),
      )
    end
  rescue ActiveRecord::StatementInvalid => e
    raise unless e.cause.is_a?(PG::InvalidRegularExpression)

    raise invalid_pattern_message(e.cause)
  end

  def invalid_pattern_message(pg_error)
    reason = pg_error.message.lines.first.to_s.sub(/\AERROR:\s*invalid regular expression:\s*/, "").strip
    %(#{@directive} takes a regular expression, and "#{@value}" is not a valid one (#{reason}). \
Use ".*" to match any characters, or "." on its own to match any value.)
  end
end
