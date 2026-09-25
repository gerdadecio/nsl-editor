# frozen_string_literal: true

# Name fields that are offered for the various types and categories of names.
module Name::Enterable
  extend ActiveSupport::Concern

  included do
  end

  def status_options
    NameStatus.options_for_category(category_for_edit)
  end

  def selected_status_id
    return name_status_id unless category_for_edit.phrase_name?

    options = status_options

    # options is an array of arrays, each inner array is [name, id]
    options.first.last if options.one?
  end

  delegate :takes_name_element?, to: :category_for_edit

  delegate :takes_rank?, to: :category_for_edit

  delegate :takes_verbatim_rank?, to: :category_for_edit

  delegate :requires_name_element?, to: :category_for_edit

  delegate :needs_top_buttons?, to: :category_for_edit

  delegate :requires_higher_ranked_parent?, to: :category_for_edit

  def category_name_for_edit
    change_category_name_to.presence || name_type.name_category.name
  end

  def category_for_edit
    NameCategory.find_by_name(category_name_for_edit)
  end

  # Default to false, so that this field
  # will not appear in shards with no config item
  # to minimize disruption of adding it
  def takes_changed_combination?
    config_name = "allow_name_changed_combination"
    allow = Rails.configuration.try(config_name)
    allow = false if allow.nil?
    allow
  end

  # Default to false, so that this field
  # will not appear in shards with no config item
  # to minimize disruption of adding it
  def takes_published_year?
    config_name = "allow_name_published_year"
    allow = Rails.configuration.try(config_name)
    allow = false if allow.nil?
    allow
  end
end
