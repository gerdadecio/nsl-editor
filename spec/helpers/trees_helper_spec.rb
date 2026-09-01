# frozen_string_literal: true

require "rails_helper"

RSpec.describe TreesHelper, type: :helper do
  subject(:messages) { helper.tree_usage_messages(instance) }

  let(:name) { create(:name) }
  let(:instance) { create(:instance, name: name) }

  # NOTES: One tree_element is referenced by a tree_version_element in each
  # version the placement appears in, so the examples below share one.
  let(:tree_element) { create(:tree_element, instance: instance, name: name) }

  # NOTES: TreeVersion#stop_if_read_only aborts the save unless the tree is
  # writable, so every tree here is built with is_read_only: false. Each tree
  # gets all three kinds of version so an example can place into whichever
  # kind it needs.
  let(:apc) { create(:tree, name: "APC", is_read_only: false) }
  let(:apc_superseded) { create(:tree_version, tree: apc, published: true) }
  let(:apc_current) { create(:tree_version, tree: apc, published: true) }
  let(:apc_draft) { create(:tree_version, tree: apc, published: false) }

  let(:foa) { create(:tree, name: "FOA", is_read_only: false) }
  let(:foa_superseded) { create(:tree_version, tree: foa, published: true) }
  let(:foa_current) { create(:tree_version, tree: foa, published: true) }

  before do
    apc.update_columns(current_tree_version_id: apc_current.id,
      default_draft_tree_version_id: apc_draft.id)
    foa.update_columns(current_tree_version_id: foa_current.id)
  end

  describe "#tree_usage_messages" do
    context "when the instance is not in any tree" do
      it "has nothing to report" do
        expect(messages).to be_empty
      end
    end

    context "when the instance is in the current version of one tree" do
      let!(:apc_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_current)
      end

      it "names the tree in the singular" do
        expect(messages).to eq(["Instance is in the currently accepted APC tree"])
      end
    end

    context "when the instance is in the current version of two trees" do
      let!(:apc_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_current)
      end
      let!(:foa_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: foa_current)
      end

      it "names both trees in the plural" do
        expect(messages)
          .to eq(["Instance is in the currently accepted APC, FOA trees"])
      end
    end

    context "when the instance is in a draft version" do
      let!(:apc_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_draft)
      end

      it "reports the draft tree" do
        expect(messages).to eq(["Instance is in the APC draft tree"])
      end
    end

    context "when the instance is in a superseded published version" do
      let!(:apc_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_superseded)
      end

      it "reports it as an old classification" do
        expect(messages)
          .to eq(["Instance is in at least one old classification: APC tree"])
      end
    end

    context "when the instance is in current, draft and historical versions" do
      let!(:apc_current_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_current)
      end
      let!(:apc_draft_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_draft)
      end
      let!(:apc_superseded_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_superseded)
      end
      let!(:foa_superseded_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: foa_superseded)
      end

      it "reports each kind of usage separately, current first" do
        expect(messages).to eq(
          ["Instance is in the currently accepted APC tree",
            "Instance is in the APC draft tree",
            "Instance is in at least one old classification: APC, FOA trees"]
        )
      end
    end

    context "when the record is a name" do
      subject(:messages) { helper.tree_usage_messages(name) }

      let!(:apc_placement) do
        create(:tree_version_element, tree_element: tree_element,
          tree_version: apc_current)
      end

      it "uses the name as the subject of the message" do
        expect(messages).to eq(["Name is in the currently accepted APC tree"])
      end
    end
  end
end
