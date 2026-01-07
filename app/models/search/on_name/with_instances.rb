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

# Core search class for Name search
#
# You can run this in the console, once you have a parsed request:
#
# search = Search::OnName::Base.new(parsed_request)
#
class Search::OnName::WithInstances
  attr_reader :names_with_instances

  def initialize(names, parsed_request = nil)
    results = []
    @parsed_request = parsed_request
    names.each do |name|
      name.display_as_part_of_concept
      results << name
      instances_to_show(name).each do |usage_rec|
        results << usage_rec
      end
    end
    @names_with_instances = results
  end

  private

  def instances_to_show(name)
    instances = Instance::AsArray::ForName.new(name).results
    # Filter to only draft instances if draft: directive is present
    if @parsed_request && @parsed_request.query_string.to_s.include?("draft:")
      instances.select { |instance| instance.respond_to?(:draft?) && instance.draft? }
    else
      instances
    end
  end
end
