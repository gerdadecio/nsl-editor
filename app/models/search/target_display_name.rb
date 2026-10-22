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
#   Maps a query target, however it was typed (singular or plural, any
#   case), to the label used for it in the search target dropdown.
#
#   The search target button shows this label, and tabs.js finds the
#   Query Help and Query Examples for the target by matching the button
#   text against the dropdown labels. A target such as "name" or
#   "Reference" runs a search, but without this it matches no label, so
#   those tabs come up blank (NSL-6000).
#
#   Targets not listed here (e.g. batch names) are returned unchanged.
class Search::TargetDisplayName
  DROPDOWN_LABELS = {
    "name" => "Names",
    "names" => "Names",
    "names_plus_instances" => "Names plus instances",
    "loader_name" => "Loader names",
    "loader_names" => "Loader names",
    "loader_names_any_batch" => "Loader names (any batch)",
    "author" => "Authors",
    "authors" => "Authors",
    "reference" => "References",
    "references" => "References",
    "ref" => "References",
    "instance" => "Instances",
    "instances" => "Instances",
    "batch_stacks" => "Batch stacks",
    "batch_review" => "Batch reviews",
    "batch_reviews" => "Batch reviews",
    "batch_reviewer" => "Batch reviewers",
    "batch_reviewers" => "Batch reviewers",
    "bulk_processing_log" => "Bulk processing logs",
    "bulk_processing_logs" => "Bulk processing logs",
    "loader_batch" => "Loader batches",
    "loader_batches" => "Loader batches",
    "user" => "Users",
    "users" => "Users",
    "org" => "Organisations",
    "orgs" => "Organisations",
    "organisation" => "Organisations",
    "organisations" => "Organisations",
  }.freeze

  def self.for(query_target)
    return query_target if query_target.blank?

    DROPDOWN_LABELS[normalise(query_target)] || query_target
  end

  def self.normalise(query_target)
    query_target.strip.downcase.delete("()").gsub(", ", "_").tr(" ", "_")
  end
end
