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

class InstanceRecordPartialTest < ActionView::TestCase
  def render_record_for(instance)
    view.lookup_context.prefixes.unshift("application")

    render partial: "application/search_results/instance/instance_record",
           locals: { search_result: instance, give_me_focus: false }
    rendered
  end

  def with_soft_delete_enabled(enabled)
    previous = Rails.configuration.try(:soft_delete_enabled)
    Rails.configuration.soft_delete_enabled = enabled
    yield
  ensure
    Rails.configuration.soft_delete_enabled = previous
  end

  test "shows the soft deleted badge when soft delete is enabled and the instance has a deleted_at" do
    instance = instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    instance.update_column(:deleted_at, Time.current)

    output = with_soft_delete_enabled(true) { render_record_for(instance) }

    assert_select_in output, "span.badge.badge-muted-orange", "soft deleted"
  end

  test "does not show the soft deleted badge when deleted_at is nil" do
    instance = instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    assert_nil instance.deleted_at

    output = with_soft_delete_enabled(true) { render_record_for(instance) }

    assert_not_includes output, "soft deleted"
    assert_select_in output, "span.badge.badge-muted-orange", false
  end

  test "does not show the soft deleted badge when soft delete is disabled even if deleted_at is set" do
    instance = instances(:metrosideros_costata_is_basionym_of_angophora_costata)
    instance.update_column(:deleted_at, Time.current)

    output = with_soft_delete_enabled(false) { render_record_for(instance) }

    assert_not_includes output, "soft deleted"
    assert_select_in output, "span.badge.badge-muted-orange", false
  end

  def assert_select_in(html, *args, &block)
    assert_select(Nokogiri::HTML::DocumentFragment.parse(html), *args, &block)
  end
end
