# frozen_string_literal: true

# Refuses a new link to a soft deleted record. Only runs when the link's
# foreign key changes, so links made before the target was soft deleted stay
# valid (check_delete_* already blocks soft deleting a record still in use).
#
# Typeaheads hide soft deleted records, but ids can still arrive from stale
# forms or hand-crafted requests, so this is the check that is relied on.
module RejectsSoftDeletedLinks
  extend ActiveSupport::Concern

  class_methods do
    # rejects_soft_deleted_links this_cites: "cited instance", parent: "parent instance"
    #
    # Associations are resolved here, so a misspelt name fails when the class
    # loads rather than on a user's save.
    def rejects_soft_deleted_links(links)
      foreign_keys = links.keys.index_with do |association|
        reflect_on_association(association)&.foreign_key ||
          raise(ArgumentError, "#{name} has no association #{association.inspect}")
      end

      validate do
        links.each do |association, label|
          reject_soft_deleted_link(association, foreign_keys[association], label)
        end
      end
    end
  end

  private

  def reject_soft_deleted_link(association, foreign_key, label)
    return unless attribute_changed?(foreign_key)
    return unless public_send(association)&.soft_deleted?

    errors.add(:base, "The #{label} has been soft deleted and cannot be used")
  end
end
