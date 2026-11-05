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

# The instance Loader 2 tab's "supplement existing concept" create. The
# concept is read from the Concept/Parent field's picked label,
# "<simple name> (<id>) ", via Loader::Names::ParentTypeahead.
class LoaderNameCreateSupplementConceptTest < ActionDispatch::IntegrationTest
  setup do
    @concept = loader_names(:zzz_test_parent_with_match)
    @instance = instances(:triodia_in_brassard)
  end

  def create_supplement(loader_name_params)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      post loader_names_path,
        params: {
          "form-task" => "supplement-existing-concept",
          loader_name: {
            loaded_from_instance_id: @instance.id,
            synonym_type: "taxonomic synonym",
            parent_id: "",
          }.merge(loader_name_params),
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should add the instance as a synonym of the picked concept" do
    assert_difference "Loader::Name.where(parent_id: #{@concept.id}).count", 1 do
      create_supplement(parent_typeahead: "#{@concept.simple_name} (#{@concept.id}) ")
    end

    assert_response :success
    synonym = Loader::Name.where(parent_id: @concept.id).order(:id).last
    assert_equal "synonym", synonym.record_type
    assert_equal @instance.id, synonym.loaded_from_instance_id
  end

  # A missing field is an error message, not a crash on nil.
  test "should refuse a create with no concept" do
    assert_no_difference "Loader::Name.count" do
      create_supplement({})
    end

    assert_response :unprocessable_content
    assert_no_match "undefined method", response.body
  end
end
