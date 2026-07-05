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

def run_test(input_query_target, expected_defined_query)
  params = ActiveSupport::HashWithIndifferentAccess.new
  params[:query_target] = input_query_target
  params[:canonical_query_target] = input_query_target
  params[:query_string] = ""
  parsed_request = Search::ParsedRequest.new(params)
  assert parsed_request.defined_query,
         "Query target #{input_query_target} should be parsed as defined query."
  assert parsed_request.defined_query.match(/\A#{expected_defined_query}\z/),
         "Query target '#{input_query_target}' should be parsed as defined \
         query '#{expected_defined_query}' not as \
         '#{parsed_request.defined_query}'"
end
