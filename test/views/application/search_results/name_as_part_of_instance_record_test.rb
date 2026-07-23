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

class NameAsPartOfInstanceRecordPartialTest < ActionView::TestCase
  setup do
    @original_soft_delete_enabled = Rails.configuration.try(:soft_delete_enabled)
  end

  teardown do
    Rails.configuration.soft_delete_enabled = @original_soft_delete_enabled
  end

  def render_record_for(name)
    render partial: "application/search_results/name_as_part_of_instance_record",
           locals: { search_result: name, give_me_focus: false }
    rendered
  end

  test "shows the soft deleted badge when soft delete is enabled and the name has a deleted_at" do
    Rails.configuration.soft_delete_enabled = true
    name = names(:another_species)
    name.update_column(:deleted_at, Time.current)

    output = render_record_for(name)

    assert_select_in output, "span.badge.badge-muted-orange", "soft deleted"
    assert_includes output, name.full_name
  end

  test "does not show the soft deleted badge when soft delete is disabled even if the name has a deleted_at" do
    Rails.configuration.soft_delete_enabled = false
    name = names(:another_species)
    name.update_column(:deleted_at, Time.current)

    output = render_record_for(name)

    assert_not_includes output, "soft deleted"
    assert_select_in output, "span.badge.badge-muted-orange", false
  end

  test "does not show the soft deleted badge when deleted_at is nil" do
    Rails.configuration.soft_delete_enabled = true
    name = names(:another_species)
    assert_nil name.deleted_at

    output = render_record_for(name)

    assert_not_includes output, "soft deleted"
    assert_select_in output, "span.badge.badge-muted-orange", false
  end

  def assert_select_in(html, *args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(html), *args, &block)
  end
end
