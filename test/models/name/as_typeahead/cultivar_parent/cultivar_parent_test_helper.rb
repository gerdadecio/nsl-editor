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

def cult_parent_suggs_shd_include(suggestions,
  given_rank_name,
  expected_rank_name,
  caller_test)
  re = Regexp.quote(expected_rank_name)
  assert(
    suggestions.collect do |h|
      /\s#{re}/.match?(h[:value]) ? 1 : 0
    end.sum.positive?,
    "suggestions for #{given_rank_name} should
         include #{expected_rank_name} [caller: #{caller_test}]",
  )
end

def cult_parent_suggs_shd_not_incl(suggestions,
  given_rank_name,
  unexpected_rank_name,
  caller_test)
  re = Regexp.quote(unexpected_rank_name)
  assert_not(
    suggestions.collect do |h|
      /\s#{re}/.match?(h[:value]) ? 1 : 0
    end.sum.positive?,
    "suggestions for #{given_rank_name} should not
             include #{unexpected_rank_name} [caller: #{caller_test}]",
  )
end

def cultivar_parent_suggestions_should_only_include(
  suggs, given_rank, expected_rank_names
)
  sorted_name_ranks.each do |rank|
    if expected_rank_names.include?(rank.name)
      cult_parent_suggs_shd_include(suggs, given_rank, rank.name, caller(1..1).first)
    else
      cult_parent_suggs_shd_not_incl(suggs, given_rank, rank.name, caller(1..1).first)
    end
  end
end

def sorted_name_ranks
  NameRank.all.sort_by(&:sort_order)
end

def show(suggestions)
  suggestions.each { |s| print("#{s[:value]}\n") }
end
