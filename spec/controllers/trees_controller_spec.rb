# spec/controllers/trees_controller_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe TreesController, type: :controller do
  describe "#resolve_parent_to_version" do
    let(:tree_element_id) { 52403480 }
    let(:draft_version_id) { 52476019 }
    let(:published_version_id) { 52386951 }

    let(:draft_version) { instance_double(TreeVersion, id: draft_version_id) }

    let(:same_version_parent) do
      instance_double(TreeVersionElement,
                      tree_version_id: draft_version_id,
                      tree_element_id: tree_element_id)
    end

    let(:cross_version_parent) do
      instance_double(TreeVersionElement,
                      tree_version_id: published_version_id,
                      tree_element_id: tree_element_id)
    end

    context "when parent is already in the target version" do
      it "returns parent unchanged without querying the DB" do
        expect(draft_version).not_to receive(:tree_version_elements)
        result = controller.send(:resolve_parent_to_version, same_version_parent, draft_version)
        expect(result).to eq(same_version_parent)
      end
    end

    context "when parent is from a different (published) version" do
      let(:tve_scope) { instance_double(ActiveRecord::Relation) }
      let(:draft_parent) { instance_double(TreeVersionElement) }

      before do
        allow(draft_version).to receive(:tree_version_elements).and_return(tve_scope)
        allow(tve_scope).to receive(:find_by!).with(tree_element_id: tree_element_id).and_return(draft_parent)
      end

      it "returns the equivalent TVE in the draft version" do
        result = controller.send(:resolve_parent_to_version, cross_version_parent, draft_version)
        expect(result).to eq(draft_parent)
      end

      it "looks up by tree_element_id in the target version" do
        expect(tve_scope).to receive(:find_by!).with(tree_element_id: tree_element_id)
        controller.send(:resolve_parent_to_version, cross_version_parent, draft_version)
      end
    end

    context "when no matching element exists in the target version" do
      let(:tve_scope) { instance_double(ActiveRecord::Relation) }

      before do
        allow(draft_version).to receive(:tree_version_elements).and_return(tve_scope)
        allow(tve_scope).to receive(:find_by!).with(tree_element_id: tree_element_id)
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          controller.send(:resolve_parent_to_version, cross_version_parent, draft_version)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
