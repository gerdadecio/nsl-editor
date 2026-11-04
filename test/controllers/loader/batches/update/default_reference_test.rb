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

# Saving the loader batch form. stimulus-autocomplete empties the Default
# Reference field's hidden id whenever the text is edited, so the visible
# text is resolved on save: blank clears the reference, text matching one
# citation saves it, and anything else is an error, never a silent clear.
class LoaderBatchUpdateDefaultReferenceTest < ActionDispatch::IntegrationTest
  setup do
    @loader_batch = loader_batch(:batch_one)
    @reference = references(:cavanilles_icones)
  end

  def update_batch(typeahead, id)
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      patch loader_batch_path(@loader_batch),
        params: {
          loader_batch: {
            name: @loader_batch.name,
            description: @loader_batch.description,
            default_reference_typeahead: typeahead,
            default_reference_id: id,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end
  end

  # A pick writes "<citation> | [type]" into the input and the id into the
  # hidden field.
  test "should save the picked default reference" do
    update_batch(@reference.typeahead_display_value, @reference.id)

    assert_response :success
    assert_equal @reference.id, @loader_batch.reload.default_reference_id
  end

  test "should clear the default reference when the input is blank" do
    @loader_batch.update_columns(default_reference_id: @reference.id)

    update_batch("", @reference.id)

    assert_response :success
    assert_nil @loader_batch.reload.default_reference_id
  end

  # The text was edited back to a full citation without a pick, so the
  # library has emptied the hidden id.
  test "should resolve typed text with no id to the matching reference" do
    update_batch(@reference.citation, "")

    assert_response :success
    assert_equal @reference.id, @loader_batch.reload.default_reference_id
  end

  test "should refuse typed text that matches no reference" do
    @loader_batch.update_columns(default_reference_id: @reference.id)

    update_batch("no such reference zzxxqq", "")

    assert_response :unprocessable_content
    assert_match "please choose Default Reference from suggestions", response.body
    assert_equal @reference.id, @loader_batch.reload.default_reference_id
  end

  # The suggestions never offer a Journal or a duplicate reference, so
  # typed text resolving to one is refused too.
  test "should refuse typed text that matches a journal" do
    @loader_batch.update_columns(default_reference_id: @reference.id)
    journal = references(:journal_for_citation_for_parent_test)

    update_batch(journal.citation, "")

    assert_response :unprocessable_content
    assert_match "please choose Default Reference from suggestions", response.body
    assert_equal @reference.id, @loader_batch.reload.default_reference_id
  end

  test "should refuse typed text that matches a duplicate reference" do
    @loader_batch.update_columns(default_reference_id: @reference.id)
    duplicate = references(:duplicate)

    update_batch(duplicate.citation, "")

    assert_response :unprocessable_content
    assert_match "please choose Default Reference from suggestions", response.body
    assert_equal @reference.id, @loader_batch.reload.default_reference_id
  end

  # Only the form sends the field; a save without it keeps the reference.
  test "should keep the default reference when the field is not sent" do
    @loader_batch.update_columns(default_reference_id: @reference.id)

    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      patch loader_batch_path(@loader_batch),
        params: { loader_batch: { description: "A changed description" } },
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    @loader_batch.reload
    assert_equal "A changed description", @loader_batch.description
    assert_equal @reference.id, @loader_batch.default_reference_id
  end

  test "should refuse a new batch whose typed text matches no reference" do
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      assert_no_difference "Loader::Batch.count" do
        post loader_batches_path,
          params: {
            loader_batch: {
              name: "Unresolved ref batch",
              default_reference_typeahead: "no such reference zzxxqq",
              default_reference_id: "",
            },
          },
          headers: { "Accept" => "application/javascript" }
      end
    end

    assert_response :unprocessable_content
    assert_match "please choose Default Reference from suggestions", response.body
  end

  test "should create a new batch with the picked default reference" do
    sign_in_as_fake_user(groups: [ "batch-loader" ]) do
      post loader_batches_path,
        params: {
          loader_batch: {
            name: "Picked ref batch",
            default_reference_typeahead: @reference.typeahead_display_value,
            default_reference_id: @reference.id,
          },
        },
        headers: { "Accept" => "application/javascript" }
    end

    assert_response :success
    assert_equal @reference.id,
                 Loader::Batch.find_by(name: "Picked ref batch").default_reference_id
  end
end
