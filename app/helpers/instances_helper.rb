# frozen_string_literal: true

# Help for Instance display
module InstancesHelper
  def instance_citation_types_names(instance)
    instance.citations.collect { |c| c.instance_type.name }
  end

  def array_of_counted_types(type_names_array)
    type_names_array.collect.each_with_object(Hash.new(0)) do |o, h|
      h[o] += 1
    end
  end

  def citation_summary(instance)
    array_of_counted_types(instance_citation_types_names(instance))
      .collect { |k, v| pluralize(v, k) }.join(" and ")
  end

  def show_field_as_linked_lookup(label,
                                  linked_entity,
                                  contents_method,
                                  url,
                                  title)
    if linked_entity
      show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    else # empty
      show_field_as_not_linked_entity(label)
    end
  end

  def show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:a,
                                        linked_entity.send(contents_method),
                                        href: url,
                                        title: title),
                            class: "field-data inline") +
                    field_label(label),
                class: "field-data")
  end

  def show_field_as_not_linked_entity(label)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:span),
                            class: "field-data inline") +
                    field_label(label),
                class: "field-data")
  end

  def field_label(label)
    content_tag(:label,
                label.as_field_description,
                class: "field-label inline pull-right")
  end

  def tab_for_instance_type(tab, row_type)
    if %w[tab_show_1 tab_edit tab_edit_notes tab_comments tab_foa_profile].include?(tab)
      tab
    elsif %w[tab_profile_details tab_edit_profile tab_batch_loader].include?(tab) && @tabs_to_offer.include?(tab)
      tab
    else
      tab_for_instance_using_row_type(tab, row_type)
    end
  end

  def tab_for_instance_using_row_type(tab, row_type)
    if row_type == "instance_record"
      tab_for_instance_record(tab)
    elsif row_type == "instance_as_part_of_concept_record"
      tab_for_iapo_concept_record(tab)
    elsif row_type == "citing_instance_within_name_search"
      tab_for_citing_instance_in_name_search(tab)
    else
      "tab_empty"
    end
  end

  def tab_for_instance_record(tab)
    if %w[tab_synonymy tab_unpublished_citation tab_classification \
          tab_copy_to_new_reference].include?(tab)
      tab
    else
      "tab_empty"
    end
  end

  # standalone
  def tab_for_iapo_concept_record(tab)
    if %w[tab_synonymy tab_unpublished_citation tab_classification
          tab_copy_to_new_reference tab_batch_loader_2].include?(tab) && @tabs_to_offer.include?(tab)
      tab
    else
      "tab_empty"
    end
  end

  def tab_for_citing_instance_in_name_search(tab)
    if %w[tab_synonymy tab_create_unpublished_citation].include?(tab)
      tab
    elsif tab == "tab_copy_to_new_reference"
      "tab_copy_to_new_reference_na"
    else
      "tab_empty"
    end
  end
end
