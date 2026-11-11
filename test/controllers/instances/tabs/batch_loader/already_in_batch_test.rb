# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# NSL-5567: when the name an instance would add is already in a batch, the
# Loader 1 and Loader 2 forms list the batches holding it and still offer
# the form, with a required "Add anyway" checkbox, so the name can be added
# to the same batch again or to another batch.
class InstanceBatchLoaderTabsAlreadyInBatchTest < ActionDispatch::IntegrationTest
  # The loader tabs are only offered for these row types.
  STANDALONE = { "row-type" => "instance_as_part_of_concept_record" }.freeze
  SYNONYM = { "row-type" => "instance_is_cited_by" }.freeze
  CONFIRM = "input[type=checkbox][name=confirm_already_in_batch][required]"

  setup do
    @was_batch_loader_aware = Rails.configuration.try("batch_loader_aware")
    Rails.configuration.batch_loader_aware = true
    @standalone = instances(:triodia_in_brassard)
    @synonym = instances(:in_stanley_angophora_lanceolata_is_a_taxonomic_synonym_of_angophora_costata_in_britten)
    @loader_name = loader_names(:accepted_one)
    @batch_name = @loader_name.loader_batch.name
  end

  teardown do
    Rails.configuration.batch_loader_aware = @was_batch_loader_aware
  end

  test "Loader 1 on a standalone instance warns, asks to confirm and offers the form" do
    @loader_name.update_columns(loaded_from_instance_id: @standalone.id)
    get_tab(@standalone, "tab_batch_loader", STANDALONE)
    assert_match warning(@batch_name, "an accepted record"), response.body
    assert_match(/\(loaded from this instance\)/, response.body)
    assert_select "form #{CONFIRM}", 1
    assert_select "h5", /to a batch/
    assert_select "input#loader-name-save"
    assert_operator response.body.index("is already in"), :<, response.body.index("to a batch</h5>"),
                    "Expected the warning at the top of the tab, above the form heading"
  end

  test "Loader 2 warns, asks to confirm and offers the form" do
    @loader_name.update_columns(loaded_from_instance_id: @standalone.id)
    get_tab(@standalone, "tab_batch_loader_2", STANDALONE)
    assert_match warning(@batch_name, "an accepted record"), response.body
    assert_select "form #{CONFIRM}", 1
    assert_select "h5", /to an existing concept/
  end

  test "warns about the same name in another batch, not loaded from this instance" do
    other = loader_names(:accepted_two)
    other.update_columns(simple_name: @standalone.name.simple_name, loaded_from_instance_id: nil)
    get_tab(@standalone, "tab_batch_loader", STANDALONE)
    assert_match warning(other.loader_batch.name, "an accepted record"), response.body
    assert_no_match(/\(loaded from this instance\)/, response.body)
    assert_select "form #{CONFIRM}", 1
  end

  test "names a synonym's parent" do
    synonym = loader_names(:synonym_parent_no_pref_match)
    synonym.update_columns(simple_name: @standalone.name.simple_name)
    get_tab(@standalone, "tab_batch_loader", STANDALONE)
    assert_match warning(synonym.loader_batch.name, "a synonym"), response.body
    assert_match(/as a synonym\s+of #{Regexp.escape(synonym.parent.simple_name)}/, response.body)
  end

  test "does not warn about a heading with the same simple name" do
    assert_empty Loader::Name.already_in_batches_for(@standalone)
    loader_names(:accepted_three).update_columns(simple_name: @standalone.name.simple_name, record_type: "heading")
    get_tab(@standalone, "tab_batch_loader", STANDALONE)
    assert_no_match(/is already in/, response.body)
    assert_select CONFIRM, 0
  end

  test "Loader 1 on an instance in no batch offers the form without a warning" do
    assert_empty Loader::Name.already_in_batches_for(@standalone)
    get_tab(@standalone, "tab_batch_loader", STANDALONE)
    assert_no_match(/is already in/, response.body)
    assert_select CONFIRM, 0
    assert_select "h5", /to a batch/
  end

  test "Loader 1 on a synonym instance offers the flip form, with its own ids" do
    @loader_name.update_columns(loaded_from_instance_id: @synonym.id)
    get_tab(@synonym, "tab_batch_loader", SYNONYM)
    assert_match warning(@batch_name, "an accepted record"), response.body
    assert_select "h5", /to a batch/
    # The attach-citing-instance form also shows, so the ids must differ.
    assert_select "input#loader-name-save", 1
    assert_select "input#loader-name-save2", 1
    assert_select "#search-result-details-error-message-container", 1
    assert_select "#search-result-details-error-message-container2", 1
  end

  test "offers the citing instance as a synonym even when it is already in a batch" do
    citer = @synonym.this_is_cited_by
    @loader_name.update_columns(loaded_from_instance_id: @synonym.id)
    in_batch = loader_names(:accepted_two)
    in_batch.update_columns(loaded_from_instance_id: citer.id)
    get_tab(@synonym, "tab_batch_loader", SYNONYM)
    assert_select "h5", /\AAdd #{Regexp.escape(citer.name.simple_name)}/
    assert_match warning(in_batch.loader_batch.name, "an accepted record"), response.body
    assert_select "form:has(input#loader-name-save) #{CONFIRM}", 1
  end

  private

  # as is a regex fragment; its spaces match any whitespace in the markup.
  def warning(batch_name, as)
    /is in batch <i>#{Regexp.escape(batch_name)}<\/i>\s+as #{as.gsub(" ", "\\s+")}/
  end

  def get_tab(instance, tab, params)
    sign_in_as_fake_user(groups: [ "edit", "batch-loader" ]) do
      get instance_tab_path(instance, tab: tab), params: params, xhr: true
    end
    assert_response :success
  end
end
