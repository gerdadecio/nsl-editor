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

# Single reference controller test.
class ReferencesEditDuplicateOfIdClearTest < ActionController::TestCase
  tests ReferencesController

  test "references edit duplicate of id clear" do
    reference = references(:an_unknown_type_already_a_duplicate)
    @request.headers["Accept"] = "application/javascript"
    username = "fred"

    reference_params = reference.attributes
    reference_params["parent_typeahead"] = reference.parent.citation
    reference_params["author_typeahead"] = reference.author.name
    reference_params["duplicate_of_id"] = reference.duplicate_of_id
    reference_params["duplicate_of_typeahead"] = "" # should clear it
    post(:update,
         params: { reference: reference_params,
                   id: reference.id },
         session: { username: username,
                    user_full_name: "Fred Jones",
                    groups: ["edit"] })
    assert_response :success
    changed = Reference.find(reference.id)
    assert !reference.duplicate_of_id.blank?, "Should have been a duplicate."
    assert changed.duplicate_of_id.blank?, "Should not be a duplicate now."
    assert changed.updated_by = username
    assert reference.updated_by != changed.updated_by,
           "Updated_by should be set"
    assert reference.updated_at != changed.updated_at,
           "Updated_at should be set"
  end
end
