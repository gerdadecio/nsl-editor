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

# Shared by the bulk loader Job classes (AddToDraftTaxonomyJob,
# CreatePreferredMatchesJob, RemoveSynConflictsJob, CreateDraftInstanceJob)
# for reporting how long a job took to run.
module Loader::Batch::BulkController::ElapsedTimeFormatting
  # Formats a duration given in seconds as "Xm Ys", e.g. 125.7 -> "2m 6s".
  #
  # The total is rounded to a whole number of seconds first, and minutes/
  # seconds are then derived from that single rounded value. Rounding the
  # minutes and seconds separately (as this used to do) can produce an
  # impossible result like "2m 60s" - e.g. for 119.6 seconds, 119.6/60
  # rounds to 2 and 119.6%60 rounds to 60, independently, even though the
  # correct rounded answer is 2m 0s.
  def format_seconds(total_seconds)
    whole_seconds = total_seconds.round
    minutes = whole_seconds / 60
    seconds = whole_seconds % 60
    "#{minutes}m #{seconds}s"
  end
end
