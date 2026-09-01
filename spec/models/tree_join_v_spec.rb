# frozen_string_literal: true

require "rails_helper"

RSpec.describe TreeJoinV, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:instance) }
    it { is_expected.to belong_to(:name) }
  end

  describe "#readonly?" do
    it "is read only, because the model is backed by a view" do
      expect(described_class.new).to be_readonly
    end
  end

  describe "scopes" do
    let(:name) { create(:name) }
    let(:instance) { create(:instance, name: name) }

    # NOTES: TreeVersion#stop_if_read_only aborts the save unless the tree is
    # writable, so every tree here is built with is_read_only: false.
    let(:accepted_tree) { create(:tree, name: "APC", accepted_tree: true, is_read_only: false) }
    let(:superseded_version) { create(:tree_version, tree: accepted_tree, published: true) }
    let(:current_version) { create(:tree_version, tree: accepted_tree, published: true) }
    let(:draft_version) { create(:tree_version, tree: accepted_tree, published: false)}

    # NOTES: One tree_element is referenced by a tree_version_element in each
    # version it appears in - that is how the same placement carries across a
    # draft, the current version and the versions it superseded.
    let(:tree_element) { create(:tree_element, instance: instance, name: name) }

    let!(:superseded_placement) { create(:tree_version_element, tree_element: tree_element, tree_version: superseded_version) }
    let!(:current_placement) { create(:tree_version_element, tree_element: tree_element, tree_version: current_version) }
    let!(:draft_placement) { create(:tree_version_element, tree_element: tree_element, tree_version: draft_version) }

    before do
      accepted_tree.update_columns(
        current_tree_version_id: current_version.id,
        default_draft_tree_version_id: draft_version.id
      )
    end

    describe ".current" do
      it "returns only the placement on the tree's current version" do
        expect(described_class.current.pluck(:tree_version_id))
          .to contain_exactly(current_version.id)
      end

      # NOTES: This is why the `old` scope was dropped. It read
      # "tree_version_id != current_tree_version_id", which is true of a draft
      # as well as of a superseded version, so drafts were reported as old
      # classifications. current/draft/historical only work as three distinct
      # groups if a draft is never counted as current.
      it "never counts a draft as current" do
        expect(described_class.current.pluck(:tree_version_id))
          .not_to include(draft_version.id)
      end
    end

    describe ".draft" do
      it "returns only the placement on the unpublished version" do
        expect(described_class.draft.pluck(:tree_version_id))
          .to contain_exactly(draft_version.id)
      end
    end

    context "when the instance is also placed in a tree that is not accepted" do
      let(:unaccepted_tree) { create(:tree, name: "FOA", accepted_tree: false, is_read_only: false) }
      let(:unaccepted_current_version) { create(:tree_version, tree: unaccepted_tree, published: true) }
      let!(:unaccepted_placement) do
        create(:tree_version_element,
          tree_element: create(:tree_element, instance: instance, name: name),
          tree_version: unaccepted_current_version)
      end

      before do
        unaccepted_tree.update_columns(
          current_tree_version_id: unaccepted_current_version.id
        )
      end

      describe ".accepted" do
        it "keeps placements in accepted trees" do
          expect(described_class.accepted.pluck(:tree_version_id))
            .to include(current_version.id)
        end

        it "excludes placements in trees that are not accepted trees" do
          expect(described_class.accepted.pluck(:tree_version_id))
            .not_to include(unaccepted_current_version.id)
        end
      end

      describe ".current_accepted" do
        it "returns only current versions of accepted trees" do
          expect(described_class.current_accepted.pluck(:tree_version_id))
            .to contain_exactly(current_version.id)
        end
      end
    end
  end
end
