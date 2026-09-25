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

def suggestions_should_include(suggestions, given_rank_name, expected_rank_name)
  # rank is the second field in the pipe-separated string
  assert(
    suggestions.collect do |h|
      re = Regexp.quote(expected_rank_name)
      if /\A#{re}\z/.match?(h[:value].split("|")[1].strip)
        1
      else
        0
      end
    end.sum.positive?,
    "#{given_rank_name} should suggest #{expected_rank_name}",
  )
end

def suggestions_should_not_include(suggestions,
  given_rank_name,
  unexpected_rank_name)
  assert_not(
    suggestions.collect do |h|
      # rank is the second field in the pipe-separated string
      rank = h[:value].split("|")[1].strip
      /\A#{Regexp.quote(unexpected_rank_name)}\z/.match?(rank) ? 1 : 0
    end.sum.positive?,
    "#{given_rank_name} should not suggest #{unexpected_rank_name}",
  )
end

def suggestions_should_only_include(suggestions,
  given_rank_name,
  expected_rank_names)
  NameRank.all.sort_by(&:sort_order).each do |rank|
    if expected_rank_names.include?(rank.name)
      suggestions_should_include(suggestions, given_rank_name, rank.name)
    else
      suggestions_should_not_include(suggestions, given_rank_name, rank.name)
    end
  end
end

# A single suggestion, like this:
#
# a_subgenus | Subgenus | legitimate | 1 instance
#
# has rank embedded in the string, as the second pipe-separated component.
#
# This method extracts that rank name and retrieves the
# matching NameRank
#
def rank_from_suggestion(suggestion)
  rank_name = suggestion[:value].sub(/^[^|]* \| /, "").sub(/ .*/, "")
  NameRank.find_by(name: rank_name)
end

def suggestion_rank_should_be_at_or_below(suggestion,
  upper_rank)
  rank = rank_from_suggestion(suggestion)
  assert(
    rank.sort_order >= upper_rank.sort_order,
    "#{rank.name} is higher than #{upper_rank.name}",
  )
end

def set_name_parent_rank_restrictions_off
  restriction = ShardConfig.find_by(name: "name parent rank restriction")
  restriction.value = "off"
  restriction.save!
end

def set_name_parent_rank_restrictions_on
  restriction = ShardConfig.find_by(name: "name parent rank restriction")
  restriction.value = "on"
  restriction.save!
end
