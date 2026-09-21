# frozen_string_literal: true

# Shared soft delete behaviour for models with a deleted_at column.
#
# A soft delete is applied by setting deleted_at on a persisted record. The
# rules for whether that is allowed live in the database (the
# check_delete_name / check_delete_instance functions), reached through the
# including model's #check_delete_result. This concern enforces those rules
# at the model layer so every code path that saves deleted_at - not only the
# soft delete controllers - is validated.
#
# Including models must implement #check_delete_result, returning an object
# that responds to #soft_delete_allowed? and #explanation.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    validate :soft_delete_must_be_allowed, on: :update, if: :soft_deleting?
  end

  def soft_deleted?
    deleted_at.present?
  end

  # True while an unsaved change is turning this record into a soft deleted
  # one, i.e. deleted_at is being set to a value.
  def soft_deleting?
    deleted_at_changed? && deleted_at.present?
  end

  def allow_soft_delete?
    return false unless soft_delete_enabled?

    check_delete_result.soft_delete_allowed?
  end

  def check_delete_result
    raise NotImplementedError,
      "#{self.class.name} must implement #check_delete_result"
  end

  private

  def soft_delete_enabled?
    Rails.configuration.try(:soft_delete_enabled) ? true : false
  end

  def soft_delete_must_be_allowed
    if deleted_at_was.present?
      errors.add(:base, "#{model_name.human} is already soft deleted")
    elsif !soft_delete_enabled?
      errors.add(:base, "Soft delete is not enabled")
    else
      result = check_delete_result
      return if result.soft_delete_allowed?

      errors.add(:base, "Soft delete not allowed: #{result.explanation}")
    end
  end
end
