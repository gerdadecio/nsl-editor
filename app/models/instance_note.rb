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
# == Schema Information
#
# Table name: instance_note
#
#  id                   :bigint           not null, primary key
#  created_by           :string(50)       not null
#  lock_version         :bigint           default(0), not null
#  source_id_string     :string(100)
#  source_system        :string(50)
#  updated_by           :string(50)       not null
#  value                :string(4000)     not null
#  created_at           :timestamptz      not null
#  updated_at           :timestamptz      not null
#  instance_id          :bigint           not null
#  instance_note_key_id :bigint           not null
#  namespace_id         :bigint           not null
#  source_id            :bigint
#
# Indexes
#
#  note_instance_index       (instance_id)
#  note_key_index            (instance_note_key_id)
#  note_source_index         (namespace_id,source_id,source_system)
#  note_source_string_index  (source_id_string)
#  note_system_index         (source_system)
#
# Foreign Keys
#
#  fk_bw41122jb5rcu8wfnog812s97  (instance_id => instance.id)
#  fk_f6s94njexmutjxjv8t5dy1ugt  (namespace_id => namespace.id)
#  fk_he1t3ug0o7ollnk2jbqaouooa  (instance_note_key_id => instance_note_key.id)
#
class InstanceNote < ActiveRecord::Base
  belongs_to :namespace, class_name: "Namespace", foreign_key: "namespace_id", optional: true
  before_create :set_defaults
  self.table_name = "instance_note"
  self.primary_key = "id"
  belongs_to :instance
  belongs_to :instance_note_key
  validates :value, presence: true
  validates :instance_note_key_id, presence: true
  validate :create_one_apc_dist_per_instance, on: [:create]
  validate :update_one_apc_dist_per_instance, on: [:update]
  validate :deprecated_instance_note_key_cannot_be_used
  scope :apc, (lambda do
                 joins(:instance_note_key)
                   .where("instance_note_key.name" =>
                          ["APC Comment", "APC Dist."])
               end)
  scope :non_apc, (lambda do
                     joins(:instance_note_key)
                       .where
                       .not("instance_note_key.name" =>
                            ["APC Comment", "APC Dist."])
                   end)
  def set_defaults
    self.namespace_id = Namespace.default.id if namespace_id.blank?
  end

  def save_with_username(username)
    self.created_by = self.updated_by = username
    save!
  end

  def update_attributes_with_username!(attributes, username)
    self.updated_by = username
    update!(attributes)
  end

  def create_one_apc_dist_per_instance
    return unless InstanceNoteKey.apc_dist.present?
    return unless instance_note_key_id == InstanceNoteKey.apc_dist.first.id
    return if instance.can_have_apc_dist?

    errors.add(:instance_note_key_id,
               "for APC Dist. Instance already has an APC Dist. note. \
                Only one APC Dist. Note allowed per instance.")
  end

  def update_one_apc_dist_per_instance
    return if instance.can_have_apc_dist?
    return unless changed_attributes.key?(:instance_note_key_id)
    return unless instance_note_key.apc_dist?

    errors.add(:instance_note_key_id,
               "for APC Dist. Instance already has an APC Dist. note. \
                Only one APC Dist. Note allowed per instance.")
  end

  def deprecated_instance_note_key_cannot_be_used
    return unless instance_note_key_id_changed?
    return unless instance_note_key.deprecated

    errors.add(:instance_note_key_id, "is deprecated, cannot be used")
  end

  def apc_dist?
    instance_note_key.apc_dist?
  end
end
