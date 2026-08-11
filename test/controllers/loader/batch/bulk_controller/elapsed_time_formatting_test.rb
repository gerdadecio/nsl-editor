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

class ElapsedTimeFormattingTest < ActiveSupport::TestCase
  include Loader::Batch::BulkController::ElapsedTimeFormatting

  test "formats whole minutes and seconds" do
    assert_equal "2m 6s", format_seconds(126)
  end

  test "formats less than a minute" do
    assert_equal "0m 45s", format_seconds(45)
  end

  test "rounds the total before splitting, so minutes and seconds never disagree" do
    # 119.6 seconds is 1m 59.6s, which rounds to 2m 0s. Rounding the minutes
    # and seconds independently (the old bug) gave "2m 60s" instead, since
    # 119.6 / 60 rounds to 2 and 119.6 % 60 rounds to 60.
    assert_equal "2m 0s", format_seconds(119.6)
  end

  test "never returns 60 as the seconds component" do
    (0..600).step(0.1) do |seconds|
      _minutes, secs = format_seconds(seconds).match(/(\d+)m (\d+)s/).captures
      assert secs.to_i < 60, "format_seconds(#{seconds}) returned #{secs}s, expected < 60"
    end
  end

  test "handles exactly zero" do
    assert_equal "0m 0s", format_seconds(0)
  end
end
