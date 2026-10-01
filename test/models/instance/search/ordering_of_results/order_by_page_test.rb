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
require "test_helper"

# Single instance model test.
class OrderByPage < ActiveSupport::TestCase
  test "approximates numeric sorting" do
    results = run_query
    # results.each_with_index do |i,ndx|
    #   puts "#{ndx}: #{i.page} - #{i.name.full_name}" if ndx < 30
    # end
    assert results.first.page == "xx 1",
           "Wrong order at 1st value: #{results[0].page}."
    assert results.second.page == "2",
           "Wrong order at 2nd value: #{results[1].page}."
    assert results.third.page == "3",
           "Wrong order at 3rd value: #{results[2].page}."
    assert results[3].page == "xx 15",
           "Wrong order at 4th value: #{results[3].page}."
    assert results[4].page == "19-20",
           "Wrong order at 5th value: #{results[4].page}."
    assert results[5].page.start_with?("xx,20,"),
           "Wrong order at 6th value: #{results[5].page}."
    assert results[9].page == "40",
           "Wrong order at 10th value: #{results[9].page}."
    assert results[10].page == "41",
           "Wrong order at 11th value: #{results[10].page}."
    assert results[15].page == "75, t. 101",
           "Wrong order at the 16th value: #{results[15].page}."
    assert results[16].page == "75, t. 102",
           "Wrong order at the 17th value: #{results[16].page}."
    assert results[17].page == "76",
           "Wrong order at the 18th value: #{results[17].page}."
    assert results[19].page == "xx 200,300",
           "Wrong order at the 19th value: #{results[19].page}."
  end

  def run_query
    Instance
      .joins(:name)
      .where
      .not(page: "exclude-from-ordering-test")
      .limit(400)
      .ordered_by_page
  end
end
