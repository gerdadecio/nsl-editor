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

# After a save, update.js.erb refreshes both Author fields - the visible
# text and the hidden id - so a later save doesn't resolve against a stale
# id left in the hidden field.
class ReferenceEditAuthorUpdateJsTest < ActionDispatch::IntegrationTest
  setup do
    stub_request(:get, %r{http://localhost:9090/nsl/services/rest/reference/apni/\d+/api/citation-strings})
      .to_return(status: 200, body: citation_strings_body, headers: {})
  end

  def citation_strings_body
    %({"action":"citation-strings",
       "result":{"citationHtml":"the html citation",
                 "citation":"the citation"}})
  end

  def update_reference(reference, author_typeahead, author_id)
    sign_in_as_fake_user(
      username: "fred",
      full_name: "Fred Jones",
      groups: [ "edit" ]
    ) do
      patch reference_path(id: reference.id),
        params: {
          reference: {
            "ref_type_id" => reference.ref_type_id,
            "title" => reference.title,
            "author_id" => author_id,
            "author_typeahead" => author_typeahead,
            "published" => reference.published,
            "ref_author_role_id" => reference.ref_author_role_id,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  test "should set the hidden id to the new author" do
    reference = references(:simple)
    author = authors(:hooker)

    update_reference(reference, author.name, author.id)

    assert_response :success
    assert_equal author.id, reference.reload.author_id
    assert_includes response.body,
                    "$('input#reference_author_id').val('#{author.id}');"
  end

  # The label carries "| <n> refs | <abbrev>" after the name; the resolver
  # cuts it off, so a picked suggestion saves as that author.
  test "should resolve the author from a picked suggestion label" do
    reference = references(:simple)
    author = authors(:hooker)

    update_reference(reference, "#{author.name} | 1 ref | Hook.", author.id)

    assert_response :success
    assert_equal author.id, reference.reload.author_id
  end

  # The name is JS-escaped, so an apostrophe can't end the string early, but
  # not HTML-escaped, which .val() would show literally as "O&#39;Brien".
  test "should js-escape but not html-escape the author name" do
    reference = references(:simple)
    author = authors(:hooker)
    author.update!(name: "O'Brien")

    update_reference(reference, "O'Brien", author.id)

    assert_response :success
    assert_includes response.body, "val('O\\'Brien')"
  end

  # The citation comes back from Services and the message from the model,
  # so both are JS-escaped: a backslash or newline in either would otherwise
  # break the response's string literal and stop the page from refreshing.
  test "should js-escape the citation and the message" do
    stub_request(:get, %r{http://localhost:9090/nsl/services/rest/reference/apni/\d+/api/citation-strings})
      .to_return(
        status: 200,
        body: { result: { citationHtml: "x", citation: "Smith's \\ book\nline2" } }.to_json,
        headers: {}
      )
    reference = references(:simple)
    author = authors(:hooker)

    update_reference(reference, author.name, author.id)

    assert_response :success
    assert_includes response.body,
                    "$('a#tab-heading').html('Smith\\&#39;s \\\\ book\\nline2');"
    assert_includes response.body,
                    "$('#search-result-details-info-message-container').html('Updated');"
  end
end
