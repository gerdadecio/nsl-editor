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

# After a save, update.js.erb refreshes both Parent fields - the visible
# citation and the hidden id - so a later save doesn't resolve against a
# stale id left in the hidden field.
class ReferenceEditParentUpdateJsTest < ActionDispatch::IntegrationTest
  setup do
    stub_request(:get, %r{http://localhost:9090/nsl/services/rest/reference/apni/\d+/api/citation-strings})
      .to_return(status: 200, body: citation_strings_body, headers: {})
    @reference = references(:a_paper)
    @journal = references(:journal_for_citation_for_parent_test)
  end

  def citation_strings_body
    %({"action":"citation-strings",
       "result":{"citationHtml":"the html citation",
                 "citation":"the citation"}})
  end

  def update_reference(parent_typeahead, parent_id)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      patch reference_path(id: @reference.id),
        params: {
          reference: {
            "ref_type_id" => @reference.ref_type_id,
            "title" => @reference.title,
            "author_id" => @reference.author_id,
            "author_typeahead" => @reference.author.name,
            "published" => @reference.published,
            "ref_author_role_id" => @reference.ref_author_role_id,
            "year" => "2004", # a paper must have a publication date
            "parent_id" => parent_id,
            "parent_typeahead" => parent_typeahead,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should set both fields to the new parent" do
    update_reference(@journal.citation, @journal.id)

    assert_response :success
    assert_equal @journal.id, @reference.reload.parent_id
    assert_includes response.body,
                    "$('input#reference-parent-typeahead').val('#{@journal.citation}');"
    assert_includes response.body,
                    "$('input#reference_parent_id').val('#{@journal.id}');"
  end

  # The label carries "| [type]" after the citation; the resolver cuts it
  # off, so a picked suggestion saves as that reference.
  test "should resolve the parent from a picked suggestion label" do
    update_reference(@journal.typeahead_display_value, @journal.id)

    assert_response :success
    assert_equal @journal.id, @reference.reload.parent_id
  end

  # JS-escaped, so an apostrophe can't end the string early, but not
  # HTML-escaped, which .val() would show literally as "O&#39;Brien".
  test "should js-escape but not html-escape the citation" do
    @journal.update_columns(citation: "O'Brien's journal")

    update_reference("O'Brien's journal", @journal.id)

    assert_response :success
    assert_includes response.body, "val('O\\'Brien\\'s journal')"
  end
end
