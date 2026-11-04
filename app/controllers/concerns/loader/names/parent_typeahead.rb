# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# Works out the loader name's parent from the form's Parent field: the
# visible text (loader_name[parent_typeahead]) and the hidden parent_id.
#
# A pick writes "<simple name> (<id>) " into the text and the id into the
# hidden field. The field is on stimulus-autocomplete, which empties the
# hidden id whenever the text is edited, so a picked label can arrive with
# no id: the id embedded in the label is used then, if it names an accepted
# or excluded loader name in this record's batch with that simple name.
# Other text is looked up by simple name within the batch.
module Loader::Names::ParentTypeahead
  private

  def work_out_parent_from_typeahead
    if params[:loader_name][:parent_typeahead].blank?
      params[:loader_name][:parent_id] = nil
    else
      check_for_mismatched_parent_typeahead
    end
  end

  # They've selected one from typeahead
  def matched_parent_typeahead_and_id?
    embedded_parent_typeahead_id(params[:loader_name][:parent_typeahead]) == params[:loader_name][:parent_id]
  end

  def embedded_parent_typeahead_id(typeahead_value)
    parent_label_parts(typeahead_value).last
  end

  def check_for_mismatched_parent_typeahead
    return if matched_parent_typeahead_and_id?
    return if resolved_parent_from_picked_label?

    possible_names = Loader::Name.where(simple_name: params[:loader_name][:parent_typeahead])
      .where(loader_batch_id: @loader_name.loader_batch_id)
    if possible_names.blank?
      raise "Parent Name supplied doesn't match any names in this record's batch"
    elsif possible_names.size == 1
      params[:loader_name][:parent_id] = possible_names.first.id
    elsif possible_names.size > 1
      ids = possible_names.map(&:id)
      if ids.include?(params[:loader_name][:parent_id].to_i)
        # do nothing, assume no change
      elsif ids.include?(@loader_name.parent_id)
        # The current parent's name, retyped: the hidden id was emptied by
        # the edit, so keep the current parent.
        params[:loader_name][:parent_id] = @loader_name.parent_id
      else
        raise "String matches too many names in this record's batch"
      end
    end
  end

  # A picked "<simple name> (<id>) " label whose hidden id was emptied.
  def resolved_parent_from_picked_label?
    name, id = parent_label_parts(params[:loader_name][:parent_typeahead])
    return false unless id.match?(/\A\d+\z/)

    parent = Loader::Name.where(record_type: %w[accepted excluded])
      .where(loader_batch_id: @loader_name.loader_batch_id)
      .find_by(id: id)
    return false if parent.nil? || parent.simple_name != name

    params[:loader_name][:parent_id] = parent.id
    true
  end

  # Splits a Loader::Name::AsTypeahead::ForParent label,
  # "<simple name> (<id>) ", into [simple name, id]. Text with no "(" comes
  # back as ["", text], and a missing label as ["", ""].
  def parent_label_parts(label)
    label = label.to_s
    raise ArgumentError, "Input too long" if label.length > 1000

    name, _, rest = label.rpartition("(")
    [ name.strip, rest.partition(")").first ]
  end
end
