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

# After a save, update.js.erb refreshes both Duplicate of fields - the
# visible citation and the hidden id - so a later save doesn't resolve
# against a stale id left in the hidden field.
class ReferenceEditDuplicateOfUpdateJsTest < ActionDispatch::IntegrationTest
  setup do
    @reference = references(:an_unknown_type_invalid_child_of_book)
    @master = references(:a_section_type_intended_master)
  end

  def update_reference(duplicate_of_typeahead, duplicate_of_id)
    params = @reference.attributes
    params["parent_typeahead"] = @reference.parent.citation
    params["author_typeahead"] = @reference.author.name
    params["duplicate_of_id"] = duplicate_of_id
    params["duplicate_of_typeahead"] = duplicate_of_typeahead
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      patch reference_path(id: @reference.id),
        params: { reference: params },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should set both fields to the new duplicate of" do
    update_reference(@master.citation, @master.id)

    assert_response :success
    assert_equal @master.id, @reference.reload.duplicate_of_id
    assert_includes response.body,
                    "$('input#reference-duplicate-of-typeahead').val('#{@master.citation}');"
    assert_includes response.body,
                    "$('input#reference_duplicate_of_id').val('#{@master.id}');"
  end

  # The label carries "| [type]" after the citation; the resolver cuts it
  # off, so a picked suggestion saves as that reference.
  test "should resolve the duplicate of from a picked suggestion label" do
    update_reference(@master.typeahead_display_value, @master.id)

    assert_response :success
    assert_equal @master.id, @reference.reload.duplicate_of_id
  end

  # JS-escaped, so an apostrophe can't end the string early, but not
  # HTML-escaped, which .val() would show literally as "O&#39;Brien".
  test "should js-escape but not html-escape the citation" do
    @master.update_columns(citation: "O'Brien's book")

    update_reference("O'Brien's book", @master.id)

    assert_response :success
    assert_includes response.body, "val('O\\'Brien\\'s book')"
  end
end
