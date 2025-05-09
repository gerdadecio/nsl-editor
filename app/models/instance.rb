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

# Instances connect Names to References.
# == Schema Information
#
# Table name: instance
#
#  id                   :bigint           not null, primary key
#  bhl_url              :string(4000)
#  cached_synonymy_html :text
#  created_by           :string(50)       not null
#  draft                :boolean          default(FALSE), not null
#  lock_version         :bigint           default(0), not null
#  nomenclatural_status :string(50)
#  page                 :string(255)
#  page_qualifier       :string(255)
#  source_id_string     :string(100)
#  source_system        :string(50)
#  uncited              :boolean          default(FALSE), not null
#  updated_by           :string(1000)     not null
#  uri                  :text
#  valid_record         :boolean          default(FALSE), not null
#  verbatim_name_string :string(255)
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  cited_by_id          :bigint
#  cites_id             :bigint
#  instance_type_id     :bigint           not null
#  name_id              :bigint           not null
#  namespace_id         :bigint           not null
#  parent_id            :bigint
#  reference_id         :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  instance_citedby_index        (cited_by_id)
#  instance_cites_index          (cites_id)
#  instance_instancetype_index   (instance_type_id)
#  instance_name_index           (name_id)
#  instance_parent_index         (parent_id)
#  instance_reference_index      (reference_id)
#  instance_source_index         (namespace_id,source_id,source_system)
#  instance_source_string_index  (source_id_string)
#  instance_system_index         (source_system)
#  no_duplicate_synonyms         (name_id,reference_id,instance_type_id,page,cites_id,cited_by_id) UNIQUE
#  uk_bl9pesvdo9b3mp2qdna1koqc7  (uri) UNIQUE
#
# Foreign Keys
#
#  fk_30enb6qoexhuk479t75apeuu5  (cites_id => instance.id)
#  fk_gdunt8xo68ct1vfec9c6x5889  (name_id => name.id)
#  fk_gtkjmbvk6uk34fbfpy910e7t6  (namespace_id => namespace.id)
#  fk_hb0xb97midopfgrm2k5fpe3p1  (parent_id => instance.id)
#  fk_lumlr5avj305pmc4hkjwaqk45  (reference_id => reference.id)
#  fk_o80rrtl8xwy4l3kqrt9qv0mnt  (instance_type_id => instance_type.id)
#  fk_pr2f6peqhnx9rjiwkr5jgc5be  (cited_by_id => instance.id)
#
class Instance < ActiveRecord::Base
  include ActionView::Helpers::TextHelper
  include InstanceTreeable
  include InstanceInTaxonomy
  include Instance::ForCopyToLoaderName

  strip_attributes
  self.table_name = "instance"
  self.primary_key = "id"
  self.sequence_name = "nsl_global_seq"
  attr_accessor :expanded_instance_type, :display_as, :relationship_flag,
                :give_me_focus,
                :show_primary_instance_type, :data_fix_in_process,
                :consider_taxo,
                :concept_warning_bypassed,
                :multiple_primary_override,
                :duplicate_instance_override

  SEARCH_LIMIT = 50
  MULTIPLE_PRIMARY_WARNING = "Saving this instance would result in multiple primary instances for the same name."
  DUPLICATE_INSTANCE_WARNING = "already has an instance with the same reference, type and page."
  belongs_to :parent, class_name: "Instance", foreign_key: "parent_id", optional: true

  has_many :profile_items, class_name: "Profile::ProfileItem", foreign_key: "instance_id"
  has_many :product_item_configs, class_name: "Profile::ProductItemConfig", through: :profile_items
  has_many :children,
           class_name: "Instance",
           foreign_key: "parent_id",
           dependent: :restrict_with_exception

  has_many :tree_join_v

  scope :product_item_config_id, -> (product_item_config_id) {
    joins(:product_item_configs)
      .where(product_item_configs: {id: product_item_config_id})
      .distinct
  }

  attr_accessor :copy_profile_items

  def self.to_csv
    attributes = %w[id]
    headings = ["Instance ID", "Name ID", "Full Name", "Reference ID",
                "Reference Citation", "Number of Notes", "Instance notes"]
    CSV.generate(headers: true) do |csv|
      csv << headings
      all.each do |instance|
        csv << [instance.id,
                instance.name.id,
                instance.name.full_name,
                instance.reference_id,
                instance.reference.citation,
                instance.instance_notes.size,
                instance.collected_notes]
      end
    end
  rescue StandardError => e
    logger.error("Could not create CSV file for instance")
    logger.error(e.to_s)
    raise
  end

  def collected_notes
    instance_notes.map { |note| "#{note.instance_note_key.name}: #{note.value}" }.join(",")
  end

  scope :ordered_by_name, -> { joins(:name).order(Arel.sql("simple_name asc")) }
  # The page ordering aims to emulate a numeric ordering process that
  # handles assorted text and page ranges in the character data.
  scope :ordered_by_page, lambda {
    raw_sql = <<-SQL
    Lpad(
      Regexp_replace(
        Regexp_replace(instance.page, '[A-z. ]','','g'),
            '[^0-9]*([0-9][0-9]*).*', '\\1')
            ||
            Regexp_replace(
              Regexp_replace(
                Regexp_replace(instance.page, '.*-.*', '~'),
              '[^~].*','0'),
              '~','Z'),
          12,'0'),
          page,
          name.full_name
    SQL
    order(Arel.sql(raw_sql))
  }

  # doesn't require join on name, unlike the above
  scope :ordered_by_page_only, lambda {
    order(Arel.sql("Lpad(
            Regexp_replace(
              Regexp_replace(page, '[A-z. ]','','g'),
            '[^0-9]*([0-9][0-9]*).*', '\\1')
            ||
            Regexp_replace(
              Regexp_replace(
                Regexp_replace(page, '.*-.*', '~'),
              '[^~].*','0'),
              '~','Z'),
          12,'0'),
          page"))
  }

  scope :in_synonymy_order, lambda {
    raw_sql = <<-SQL
    case nomenclatural
      when true then
      case instance_type.name = 'basionym'
        when true then 1
        else 2
      end
      else 3
    end,
    case taxonomic
        when true then
          case pro_parte
            when true then 2
            else 1
          end
        when false then
          case nomenclatural
            when true then
              case pro_parte
                when true then 4
                else 3
              end
            else
              98
          end
        else 99
    end,
    ref_that_cites.iso_publication_date,
    instance_type.sort_order,
    case instance_type.name
      when 'replaced synonym' then 2
      when 'common name' then 99
      when 'vernacular name' then 99
      else 3
    end,
    case ns.name
      when 'orth. var.' then 2
      else 1
    end
    SQL
    order(Arel.sql(raw_sql))
  }

  scope :ref_synonymy_order, lambda {
    raw_sql = <<-SQL
    case nomenclatural
      when true then 1
      else 2
    end,
    case taxonomic
        when true then
          case pro_parte
            when true then 2
            else 1
          end
        when false then
          case nomenclatural
            when true then
              case pro_parte
                when true then 4
                else 3
              end
            else
              98
          end
        else 99
    end,
    instance_type.sort_order,
    case instance_type.name
      when 'basionym' then 1
      when 'replaced synonym' then 2
      when 'common name' then 99
      when 'vernacular name' then 99
      else 3
    end,
    case name_status.name
      when 'orth. var.' then 2
      else 1
    end
    SQL
    order(Arel.sql(raw_sql))
  }

  scope :created_n_days_ago,
        ->(n) { where("current_date - created_at::date = ?", n) }
  scope :updated_n_days_ago,
        ->(n) { where("current_date - updated_at::date = ?", n) }
  query = "current_date - created_at::date = ? " \
          "or current_date - updated_at::date = ?"
  scope :changed_n_days_ago,
        ->(n) { where(query, n, n) }

  scope :created_in_the_last_n_days,
        ->(n) { where("current_date - created_at::date < ?", n) }
  scope :updated_in_the_last_n_days,
        ->(n) { where("current_date - updated_at::date < ?", n) }

  scope :for_ref, ->(ref_id) { where(reference_id: ref_id) }
  scope :for_ref_and_correlated_on_name_id, lambda \
    { |ref_id|
                                              where(["exists (select null from instance i2
             where i2.reference_id = ? and instance.name_id = i2.name_id)",
                                                     ref_id])
                                            }
  # scope :order_by_name_full_name, -> { joins(:name).order(name: [:full_name])}
  scope :order_by_name_full_name, -> { joins(:name).order(Arel.sql(" name.full_name ")) }

  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id"
  belongs_to :reference
  belongs_to :author, optional: true
  # Name and instance type are not optional but the belongs_to change
  # was causing test failures, probably because it was intervening
  # too early in the process
  #
  # rails 6 change to explictly make name optional when checking fk
  belongs_to :name, optional: true
  # rails 6 change to explictly make instance_type optional when checking fk
  belongs_to :instance_type, optional: true
  belongs_to :this_cites, class_name: "Instance", foreign_key: "cites_id", optional: true
  has_many :reverse_of_this_cites,
           class_name: "Instance",
           inverse_of: :this_cites,
           foreign_key: "cites_id"
  has_many :citeds, class_name:
      "Instance",
                    inverse_of: :this_cites,
                    foreign_key: "cites_id"

  belongs_to :this_is_cited_by,
             class_name: "Instance",
             foreign_key: "cited_by_id", optional: true

  has_many :reverse_of_this_is_cited_by,
           class_name: "Instance",
           inverse_of: :this_is_cited_by,
           foreign_key: "cited_by_id"

  has_many :citations,
           class_name: "Instance",
           inverse_of: :this_is_cited_by,
           foreign_key: "cited_by_id"

  has_many :synonyms,
           class_name: "Instance",
           inverse_of: :this_is_cited_by,
           foreign_key: "cited_by_id"

  has_many :instance_notes,
           dependent: :restrict_with_error

  has_many :loader_names,
           class_name: "Loader::Name",
           foreign_key: "loaded_from_instance_id"

  # has_many :apc_instance_notes,
  #         class_name: "InstanceNote",
  #         dependent: :restrict_with_error,
  #         -> { "where instance_note_key_id in
  #         (select id from instance_note_key
  #         where ink.name in ('APC Comment', 'APC Dist.')" }

  has_many :comments
  # TODO: remove if redundant
  has_many :nodes, class_name: "TreeNode"
  has_many :tree_elements, class_name: "Tree::Element"

  validates_presence_of :name_id,
                        :reference_id,
                        :instance_type_id,
                        message: "cannot be empty."

  validates :name_id,
            unless: :duplicate_instance_override?,
            uniqueness:
                { scope: %i[reference_id
                            instance_type_id
                            cites_id
                            cited_by_id
                            page],
                  message: lambda do |_object, data|
                             " - instance for Name #{data[:value]} already exists with the same reference, type and page."
                           end }

  validate :relationship_ref_must_match_cited_by_instance_ref,
           :synonymy_name_must_match_cites_instance_name,
           :cites_id_with_no_cited_by_id_is_invalid,
           :cannot_cite_itself,
           :cannot_be_cited_by_itself
  validate :synonymy_must_keep_cites_id, on: :update
  validate :name_id_must_not_change, on: :update
  validate :standalone_reference_id_can_change_if_no_dependents, on: :update
  validate :name_cannot_be_synonym_of_itself
  validate :name_cannot_be_double_synonym
  validate :restrict_change_to_accepted_concept_synonymy
  validate :only_one_primary_instance_per_name

  before_validation :set_defaults
  before_create :set_defaults

  def draft?
    draft
  end

  def duplicate_instance_override?
    @duplicate_instance_override || false
  end

  def restrict_change_to_accepted_concept_synonymy
    return if concept_warning_bypassed?
    return if standalone_or_unpublished_citation?
    return unless this_is_cited_by.accepted_concept?

    errors.add(:base, "You are trying to change an accepted concept's synonymy.")
  end

  def concept_warning_bypassed?
    @concept_warning_bypassed || false
  end

  def both_names_are_accepted_concepts?
    this_is_cited_by.name.present? &&
      this_is_cited_by.name.accepted_concept? &&
      this_cites.name.accepted_concept?
  end

  # Okay if no instance type (need instance type for next test)
  # Okay if not a primary instance
  # Okay if zero current primary instances
  # Okay if 1 primary instance and this is it (updating)
  # Okay if >1 primary instance and this is one of them and instance_type is
  #      not changing
  # Okay if updating but instance_type has not changed
  # Otherwise, reject
  def only_one_primary_instance_per_name
    return if multiple_primary_override
    return unless instance_type_is_primary?
    return if name.primary_instances.empty?
    return if current_record_is_the_only_primary_instance?
    return if an_update_not_changing_type?

    errors.add(:base, MULTIPLE_PRIMARY_WARNING)
  end

  def instance_type_is_primary?
    instance_type.present? && instance_type.primary?
  end

  # current record is the only primary instance (being updated)
  def current_record_is_the_only_primary_instance?
    name.primary_instances.map(&:id).include?(id) &&
      name.primary_instances.size == 1
  end

  # Don't reject updates that do not change instance type
  def an_update_not_changing_type?
    if new_record?
      false
    else
      !changed.include?("instance_type_id")
    end
  end

  def name_cannot_be_double_synonym
    return if standalone?
    return if unpublished_citation?
    return unless double_synonym?

    if misapplied?
      errors.add(:base, "A name cannot be placed in synonymy twice
      (non-misapplication synonym is already present).")
    else
      errors.add(:base, "A name cannot be placed in synonymy twice, except as a
      misapplication.")
    end
  end

  # Synonym is a double if
  # - is a synonym
  # - there exists at least one other synonym
  #   - for the original name
  #   - for this name
  #   - that is not a misapplication type of instance
  #
  #   Case A: you are adding a misapplication
  #     Case A1: the possible doubles are all misapplications - accept
  #     Case A2: the possible doubles include a non-misapplication - reject
  #
  #   Case B: you are adding a non-misapplication - keep testing
  #     Case B1: there is at least 1 misapplication - reject
  #     Case B2: there is at least 1 non-misapplication - reject
  def double_synonym?
    if misapplied?
      double_synonym_case_a?
    else
      double_synonym_case_b?
    end
  end

  def double_synonym_case_a?
    !Instance.where(["instance.id != ? and instance.cited_by_id = ?",
                     id || 0,
                     this_is_cited_by.id])
             .joins(:this_cites)
             .where(this_cites_instance: { name_id: name.id })
             .joins(:instance_type)
             .where(instance_type: { misapplied: false })
             .empty?
  end

  def double_synonym_case_b?
    !Instance.where(["instance.id != ? and instance.cited_by_id = ?",
                     id || 0,
                     this_is_cited_by.id])
             .joins(:this_cites)
             .where(this_cites_instance: { name_id: name.id })
             .empty?
  end

  def name_cannot_be_synonym_of_itself
    return if cited_by_id.blank?
    return if cites_id.blank?
    return unless this_is_cited_by.name_id == this_cites.name_id

    errors.add(:base, "A name cannot be a synonym of itself")
  end

  def apc_instance_notes
    instance_notes.apc
  end

  def non_apc_instance_notes
    instance_notes.non_apc
  end

  def self.changed_in_the_last_n_days(n)
    Instance.where("current_date - created_at::date < ? " \
                   "or current_date - updated_at::date < ?",
                   n, n)
  end

  def name_id_must_not_change
    errors.add(:base, "You cannot use a different name.") if name_id_changed?
  end

  # A standalone instance with no dependents can change reference.
  def standalone_reference_id_can_change_if_no_dependents
    return unless reference_id_changed? &&
                  standalone? &&
                  reverse_of_this_is_cited_by.present?

    errors(:base, "this instance has relationships, ")
    errors(:base, "so you cannot alter the reference.")
  end

  # Update of name_id is not allowed.
  # Update of reference_id is allowed only for standlone instances
  # and only if they have no is_cited_by [relationship]
  # instance children.
  def update_allowed?
    !name_id_changed? &&
      (!reference_id_changed? ||
          (standalone? && reverse_of_this_is_cited_by.blank?))
  end

  def update_reference_allowed?
    standalone? && reverse_of_this_is_cited_by.blank?
  end

  def relationship_ref_must_match_cited_by_instance_ref
    return unless relationship? &&
                  !(reference.id == this_is_cited_by.reference.id)

    errors.add(:reference_id,
               "must match cited by instance reference")
  end

  def to_s
    "#{id}; \n#{type_of_instance} instance; \nname: #{name.try('full_name')}:
    \nref: #{reference.try('citation')}; \ncited_by: #{cited_by_id}
    \ncited by ref: #{this_is_cited_by.try('reference').try('citation')}
    \ncites name: #{this_cites.try('name').try('full_name')}"
  rescue StandardError => e
    "Error in to_s: #{e}"
  end

  def synonymy_name_must_match_cites_instance_name
    return if !synonymy? || name.id == this_cites.name.id

    errors.add(:name_id, "must match cites instance name")
  end

  def cites_id_with_no_cited_by_id_is_invalid
    return unless cites_id.present? && cited_by_id.blank?

    errors(:base, "A cites id with no cited by id is invalid.")
  end

  def cannot_cite_itself
    return if !synonymy? || id != cites_id

    errors.add(:base, "cannot cite itself")
  end

  def cannot_be_cited_by_itself
    return if !relationship? || id != cited_by_id

    errors.add(:name_id, "cannot be cited by itself")
  end

  def synonymy_must_keep_cites_id
    return if cites_id.present?
    return if Instance.find(id).cites_id.nil? || data_fix_in_process

    errors.add(:cites_id, "cannot be removed once saved")
  end

  def relationship_flag
    true if cites_id || cited_by_id
  end

  # The four plus one types of instance -
  # based on null/not null state of the two fields:
  # - cited_by_id
  # - cites_id
  def standalone?
    cited_by_id.nil? && cites_id.nil?
  end

  def secondary_reference?
    instance_type.secondary_instance?
  end

  def synonymy?
    relationship? && cites_id.present?
  end

  def unpublished_citation?
    relationship? && cites_id.nil?
  end

  def unrecognised?
    cited_by_id.nil? && cites_id.present?
  end

  def standalone_or_unpublished_citation?
    standalone? || unpublished_citation?
  end

  def type_of_instance
    if standalone?
      "Standalone"
    elsif synonymy?
      "Synonymy"
    elsif unpublished_citation?
      "Unpublished citation"
    else
      "Unknown - unrecognised type"
    end
  end

  def is_cited_by
    Instance.where(cited_by_id: id)
            .joins(:instance_type, :name)
            .joins("inner join name_status ns on name.name_status_id = ns.id")
            .joins("left outer join instance cites on instance.cites_id = cites.id")
            .joins("left outer join reference ref_that_cites on cites.reference_id = ref_that_cites.id")
            .in_synonymy_order
            .collect do |instance|
      instance.display_as = "cited-by-instance"
      instance
    end
  end

  def cites_this
    return if cited_by_id.nil?

    instance = Instance.find_by_id(cited_by_id)
    instance.expanded_instance_type = instance_type.name + " of"
    instance.display_as = "cites-this-instance"
    instance
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save!
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update!(attributes)
  end

  def fresh?
    created_at > 1.hour.ago
  end

  def allow_delete?
    instance_notes.blank? &&
      reverse_of_this_cites.blank? &&
      reverse_of_this_is_cited_by.blank? &&
      comments.blank? &&
      !in_any_tree? &&
      children.empty? &&
      not_linked_to_loader_name_matches? &&
      profile_items.blank?
  end

  # This is not handled via an instance association because the loader is only
  # in the apni database for now.
  def linked_to_loader_name_matches?
    if Rails.configuration.try(:batch_loader_aware)
      Loader::Name::Match.where(instance_id: id).size > 0 ||
        Loader::Name::Match.where(standalone_instance_id: id).size > 0 ||
        Loader::Name::Match.where(relationship_instance_id: id).size > 0
    else
      false
    end
  end

  # This is not handled via an instance association because the loader is so far
  # only in the apni database.
  def not_linked_to_loader_name_matches?
    !linked_to_loader_name_matches?
  end

  def anchor_id
    "Instance-#{id}"
  end

  def set_defaults
    self.namespace_id = Namespace.default.id if namespace_id.blank?
    self.draft = "f" if draft.blank?
  end

  # simple i.e. not a relationship instance
  # Deprecate simple - standalone is the accepted term now
  def simple?
    standalone?
  end

  # simple i.e. not a relationship instance
  # Should be based on instance_type.relationship flag
  def relationship?
    !standalone?
  end

  def type
    standalone? ? "standalone" : "relationship"
  end

  def misapplied?
    instance_type.misapplied?
  end

  def unsourced?
    instance_type.unsourced?
  end

  def accepts_notes?
    !relationship? || (misapplied? && unsourced?)
  end

  def accepts_adnots?
    !relationship?
  end

  def self.find_references
    ->(title) { Reference.where(" lower(title) = lower(?)", title) }
  end

  def self.find_names
    ->(term) { Name.where(" lower(simple_name) = lower(?)", term) }
  end

  def self.expansion(search_string)
    expand_wanted = !search_string.match(/expand:/).nil?
    logger.debug("display should be:  expand_wanted: #{expand_wanted}")
    [expand_wanted, search_string.gsub(/expand:[^ ]*/, "")]
  end

  def self.extract_query_token(search_string, requested_token)
    token = search_string.match(/#{requested_token}:[^ ]*/)
    token.to_s
  end

  def self.consume_token(search_string, requested_token)
    found_token = search_string.match(/#{requested_token.downcase}:[^ ]*/)
    [!found_token.blank?,
     search_string.gsub(/#{requested_token.downcase}:/, "")]
  end

  def self.get_id_for(search_string, query_token)
    pair = extract_query_token(search_string, query_token)
    pair.gsub(/#{query_token}:/, "")
  end

  def self.reverse_of_cites_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    instance.present? ? instance.reverse_of_this_cites : []
  end

  def self.reverse_of_cited_by_id_query(instance_id)
    instance = Instance.find_by(id: instance_id.to_i)
    instance.present? ? instance.reverse_of_this_is_cited_by : []
  end

  def display_as_part_of_concept
    self.display_as = :instance_as_part_of_concept
    self
  end

  def display_within_reference
    self.display_as = :instance_within_reference
    self
  end

  def display_as_citing_instance_within_name_search
    self.display_as = :citing_instance_within_name_search
    self
  end

  # Notes:
  # - sets the updated_by column to audit the user who is deleting the record.
  # - avoid validation on that update - otherwise the delete will not occur.
  def delete_as_user(username)
    update_attribute(:updated_by, username)
    Instance::AsServices.delete(id)
  rescue StandardError => e
    logger.error("delete_as_user exception: #{e}")
    raise
  end

  # Assemble the attributes and related entities into a standard CSV
  # view of an instance.
  def fields_for_csv
    attributes
      .values_at("id", "name_id")
      .concat(name.attributes.values_at("full_name"))
      .concat(attributes.values_at("reference_id"))
      .concat(reference.attributes.values_at("citation"))
      .concat(instance_notes
                    .sort do |x, y|
                x.instance_note_key.sort_order <=> y.instance_note_key.sort_order
              end
                    .each
                    .collect { |n| [n.instance_note_key.name, n.value] })
      .flatten
  end

  # Sometimes need to know if an instance has an APC Dist. instance note.
  def apc_dist_note?
    instance_notes.collect do |n|
      n.instance_note_key.name
    end.include?(InstanceNoteKey::APC_DIST)
  end

  def can_have_apc_dist?
    instance_notes.to_a.keep_if { |n| n.instance_note_key.apc_dist? }.size.zero?
  end

  def year
    reference.year
  end

  def listing_citation
    (reference.present? ? reference.citation_html : "") +
      (page.present? ? ": #{page}" : "") +
      (show_primary_instance_type && instance_type&.primary_instance? ? " [#{instance_type.name}]" : "") +
      (consider_taxo && show_taxo? ? ": #{accepted_taxonomy_widget}" : "") +
      (draft? ? "<span class='highlight'>[DRAFT]</span>" : "")
  end

  def accepted_taxonomy_widget
    '<span class="taxo-icon-container no-decoration">' +
      (name.excluded_concept? ? "<i class='fa fa-ban apc' aria-hidden='true'></i><span class='apc small strong' title='Excluded from APC'>APC</span>" : "") +
      (name.excluded_concept? ? "" : "<i class='fa fa-check apc' aria-hidden='true'></i><span class='apc small strong' title='In APC'>APC</span>") +
      "</span>"
  end
end
