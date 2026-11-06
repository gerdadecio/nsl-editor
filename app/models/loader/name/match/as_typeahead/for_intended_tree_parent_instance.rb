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

# Provide typeahead suggestions based on a search term.
#
# Offers scientific names, not soft deleted, as a loader name match's
# intended taxonomy parent.
class Loader::Name::Match::AsTypeahead::ForIntendedTreeParentInstance
  attr_reader :suggestions,
    :params

  SEARCH_LIMIT = 50

  # The names this field can offer: scientific, not soft deleted.
  def self.offered_names
    Name.not_soft_deleted
      .joins(:name_type)
      .where(name_type: { name: "scientific" })
  end

  def initialize(params)
    @params = params
    # Strings only: an array or hash term (e.g. ?term[]=x) gets no
    # suggestions rather than a NoMethodError.
    @term = params[:term].is_a?(String) ? params[:term] : ""
    @suggestions = @term.blank? ? [] : query
  end

  def prepared_search_term
    @term.tr("*", "%").downcase + "%"
  end

  # Select on full name
  # Show full name and name status (unless 'legitimate')
  # CodeQL on github alerts to this query, in particular to the use of
  # prepared_search_term to pass param value into the query - but the code
  # follows the Rails guide technique for passing values into a query via
  # a placeholder in a way that specifically counters SQL Injection.
  # I will dismiss the alert.
  def core_query
    self.class.offered_names
      .joins(:name_rank)
      .joins(:name_status)
      .where([
        "lower(f_unaccent(name.full_name)) like lower(f_unaccent(?))",
        prepared_search_term
      ])
      .select("name.id, name.full_name, case name_status.name when 'legitimate' then null else name_status.name end as status")
      .order("name_rank.sort_order, name.full_name")
      .limit(SEARCH_LIMIT)
  end

  def query
    @qry = core_query
    @qry = @qry.collect do |qry|
      {
        value: "#{qry.full_name} #{qry.status}",
        id: qry.id,
      }
    end
  end
end
