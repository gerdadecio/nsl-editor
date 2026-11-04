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

# Saving a loader name synonym's Parent field. stimulus-autocomplete empties
# the hidden parent_id whenever the text is edited, so a picked
# "<simple name> (<id>) " label can arrive with no id and is resolved from
# the id it embeds.
class LoaderNameUpdateParentTest < ActionDispatch::IntegrationTest
  setup do
    @loader_name = loader_names(:synonym_guards_pass)
    @old_parent = loader_names(:zzz_test_parent_with_match)
    @new_parent = loader_names(:zzz_test_parent_no_match)
  end

  def update_parent(typeahead, id)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      patch loader_name_path(@loader_name),
        params: { loader_name: { parent_typeahead: typeahead, parent_id: id } },
        headers: { "Accept" => "application/javascript" }
    end
  end

  def label_for(loader_name)
    "#{loader_name.simple_name} (#{loader_name.id}) "
  end

  test "should save the picked parent" do
    update_parent(label_for(@new_parent), @new_parent.id)

    assert_response :success
    assert_equal @new_parent.id, @loader_name.reload.parent_id
  end

  test "should save a picked parent whose hidden id was emptied" do
    update_parent(label_for(@new_parent), "")

    assert_response :success
    assert_equal @new_parent.id, @loader_name.reload.parent_id
  end

  test "should resolve a typed simple name with no id" do
    update_parent(@new_parent.simple_name, "")

    assert_response :success
    assert_equal @new_parent.id, @loader_name.reload.parent_id
  end

  test "should keep the parent when the field is left as loaded" do
    update_parent(@old_parent.simple_name, @old_parent.id)

    assert_response :success
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end

  # Another name in the batch shares the parent's simple name, and the user
  # retyped it without a pick, which emptied the hidden id.
  test "should keep the current parent when its retyped name is ambiguous" do
    namesake = @old_parent.dup
    namesake.save!

    update_parent(@old_parent.simple_name, "")

    assert_response :success
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end

  test "should refuse an ambiguous name that isn't the current parent" do
    namesake = @new_parent.dup
    namesake.save!

    update_parent(@new_parent.simple_name, "")

    assert_response :unprocessable_content
    assert_match "too many names", response.body
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end

  test "should refuse text that matches no name in the batch" do
    update_parent("no such parent zzxxqq", "")

    assert_response :unprocessable_content
    assert_match "match any names in this record", response.body
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end

  # An embedded id from another batch is not trusted.
  test "should refuse a label naming a loader name in another batch" do
    other_batch = loader_names(:accepted_two)
    update_parent(label_for(other_batch), "")

    assert_response :unprocessable_content
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end

  # The embedded id must belong to the name the label shows.
  test "should refuse a label whose name and embedded id disagree" do
    update_parent("#{@old_parent.simple_name} (#{@new_parent.id}) ", "")

    assert_response :unprocessable_content
    assert_equal @old_parent.id, @loader_name.reload.parent_id
  end
end
