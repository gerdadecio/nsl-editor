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
require "ostruct"

# Callers of detail_line that pass stored text or build HTML themselves.
class DetailLineCallersTest < ActionView::TestCase
  UNSAFE = %(<script>alert("x")</script><img src="x" onerror="alert('y')"><i>Eucalyptus</i> note)

  setup do
    view.lookup_context.prefixes |= [ "application" ]
  end

  def assert_no_active_content
    html = Nokogiri::HTML::DocumentFragment.parse(rendered)
    assert_empty html.css("script"), "rendered a <script> element"
    assert_empty html.css("[onerror]"), "rendered an onerror attribute"
  end

  def review_comment(text)
    reviewer = loader_batch_batch_reviewers(:name_reviewer_for_batch_one)
    @current_user = OpenStruct.new(username: reviewer.user.user_name)
    Loader::Name::Review::Comment.create!(
      loader_name: loader_names(:accepted_one),
      batch_review_period: loader_batch_batch_review_batch_review_period(:review_period_one),
      batch_reviewer: reviewer,
      name_review_comment_type: loader_name_review_comment_type(:general_comment_type),
      comment: text,
      context: "unknown",
      created_by: "test",
      updated_by: "test"
    )
  end

  %w[loader/names/review/tabs/common/one_comment loader/names/tabs/rev_comments/one_comment].each do |partial|
    test "#{partial} sanitizes the review comment" do
      render(partial: partial, locals: { comment: review_comment(UNSAFE) })

      assert_no_active_content
      assert_includes rendered, "<i>Eucalyptus</i> note"
    end

    test "#{partial} keeps the remote edit link working" do
      render(partial: partial, locals: { comment: review_comment("A comment") })

      link = Nokogiri::HTML::DocumentFragment.parse(rendered).at_css("a.blue")
      assert_equal "(edit)", link.text
      assert_equal "true", link["data-remote"]
      assert_equal "false", link["data-turbo"]
    end
  end

  test "parent record link on a child loader name stays a link" do
    @loader_name = loader_names(:synonym_parent_no_pref_match)
    assert @loader_name.child?
    render(partial: "loader/names/tabs/details/link_to_context_view")

    link = Nokogiri::HTML::DocumentFragment.parse(rendered).at_css("a.blue.underline")
    assert_equal @loader_name.parent.simple_name, link.text
    assert_equal "See parent", link["title"]
    assert_includes rendered, "Parent record: <a"
  end

  test "instance note value is sanitized" do
    note = instance_notes(:one)
    note.value = UNSAFE
    render(partial: "instance_notes/show", locals: { instance_note: note })

    assert_no_active_content
    assert_includes rendered, "<i>Eucalyptus</i> note"
  end
end
