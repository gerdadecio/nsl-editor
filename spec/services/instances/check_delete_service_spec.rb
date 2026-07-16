# frozen_string_literal: true

require "rails_helper"

describe Instances::CheckDeleteService do
  subject(:result) { described_class.call(instance: instance).result }

  let(:instance) { create(:instance) }

  def create_referencing_instance(attributes)
    if attributes[:cites_id] && !attributes[:cited_by_id]
      attributes[:cited_by_id] = create(:instance).id
    end
    referencing = build(:instance,
      name: instance.name,
      reference: instance.reference,
      namespace_id: instance.namespace_id,
      instance_type: instance.instance_type,
      page: "referencing instance",
      **attributes)
    referencing.save!(validate: false)
    referencing
  end

  def tree_with_element_in(version_key)
    tree = create(:tree, is_read_only: false)
    version = create(:tree_version, tree: tree)
    tree.update_columns(version_key => version.id)
    tree_element = create(:tree_element, instance: instance)
    create(:tree_version_element,
      tree_element: tree_element,
      tree_version: version,
      element_link: "http://example.com/tve/#{version_key}-#{instance.id}")
  end

  describe "#execute" do
    context "when the instance has notes" do
      before do
        create(:instance_note,
          instance: instance,
          instance_note_key: create(:instance_note_key, deprecated: false),
          namespace_id: instance.namespace_id)
      end

      it "blocks the delete" do
        expect(result).to have_attributes(
          action_code: 0,
          delete_action: "BLOCK",
          explanation: "Instance has notes"
        )
      end
    end

    %i[cites_id cited_by_id parent_id].each do |foreign_key|
      context "when the instance is referenced via #{foreign_key} by a live instance" do
        before { create_referencing_instance(foreign_key => instance.id) }

        it "blocks the delete" do
          expect(result).to have_attributes(
            action_code: 0,
            delete_action: "BLOCK",
            explanation: "Instance is referenced by a live instance"
          )
        end
      end
    end

    context "when the instance is referenced only by a soft-deleted instance" do
      before do
        create_referencing_instance(cites_id: instance.id, deleted_at: Time.current)
      end

      it "ignores the reference and allows a hard delete" do
        expect(result).to have_attributes(
          action_code: 2,
          delete_action: "DELETE",
          explanation: "Instance has no instance or tree dependents"
        )
      end
    end

    context "when the instance has no notes, references or tree usage" do
      it "allows a hard delete" do
        expect(result).to have_attributes(
          action_code: 2,
          delete_action: "DELETE",
          explanation: "Instance has no instance or tree dependents"
        )
      end
    end

    context "when the instance is used only in past tree versions" do
      before do
        tree = create(:tree, is_read_only: false)
        past_version = create(:tree_version, tree: tree)
        current_version = create(:tree_version, tree: tree)
        tree.update_columns(current_tree_version_id: current_version.id)
        tree_element = create(:tree_element, instance: instance)
        create(:tree_version_element,
          tree_element: tree_element,
          tree_version: past_version,
          element_link: "http://example.com/tve/past-#{instance.id}")
      end

      it "allows a soft delete" do
        expect(result).to have_attributes(
          action_code: 1,
          delete_action: "SOFT_DELETE",
          explanation: "Instance is used only in past tree versions"
        )
      end
    end

    context "when the instance is used in a current tree version" do
      before { tree_with_element_in(:current_tree_version_id) }

      it "blocks the delete" do
        expect(result).to have_attributes(
          action_code: 0,
          delete_action: "BLOCK",
          explanation: "Instance is used in a current or draft tree version"
        )
      end
    end

    context "when the instance is used in a default draft tree version" do
      before { tree_with_element_in(:default_draft_tree_version_id) }

      it "blocks the delete" do
        expect(result).to have_attributes(
          action_code: 0,
          delete_action: "BLOCK",
          explanation: "Instance is used in a current or draft tree version"
        )
      end
    end
  end
end
