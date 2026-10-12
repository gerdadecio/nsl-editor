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

# app/views/application/_detail_line.html.erb renders the "value ... label"
# rows on most Details tabs. Values the caller has already marked safe (links,
# form fields, sanitize output) pass through; anything else is sanitized, so
# stored text can't inject script but keeps ordinary formatting and entities.
class DetailLinePartialTest < ActionView::TestCase
  def render_info(info)
    render(partial: "application/detail_line", locals: { info: info, label: "label" })
    Nokogiri::HTML::DocumentFragment.parse(rendered).at_css("span.float-start")
  end

  test "strips script and event handlers from a plain value" do
    span = render_info(%(<script>alert("x")</script><img src="x" onerror="alert('y')">ok))

    assert_empty span.css("script")
    assert_empty span.css("[onerror]")
    # The script's text is left behind as plain, inert text.
    assert_includes span.text, "ok"
  end

  test "keeps ordinary formatting and entities in a plain value" do
    render_info(%(<i>Eucalyptus</i> sens. lat.:&nbsp;12 &mdash; <span class="red">note</span>))

    assert_includes rendered, "<i>Eucalyptus</i>"
    # sanitize keeps &nbsp; and turns &mdash; into the same character
    assert_includes rendered, "&nbsp;12 — "
    assert_includes rendered, %(<span class="red">note</span>)
  end

  test "passes an already-safe link through unchanged, data attributes and all" do
    link = link_to("(edit)", "/somewhere", remote: true, data: { turbo: false }, tabindex: 5, class: "blue")
    render_info(link)

    assert_includes rendered, link
  end

  test "renders numbers and booleans as before" do
    assert_equal "42", render_info(42).text.strip
    assert_equal "true", render_info(true).text.strip
  end

  test "shows a blank placeholder for nil and empty values" do
    assert_includes render_info(nil)["class"], "no-color"
    assert_includes render_info("")["class"], "no-color"
  end
end
