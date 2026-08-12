# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Instance::Treeable do
  describe '#in_published_trees' do
    context 'when instance is in a single published tree' do
      let(:instance) { create(:instance) }
      let(:tree) { create(:tree, name: 'Published Tree', is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns the instance with tree details' do
        result = instance.in_published_trees

        expect(result).to be_present
        expect(result.first.id).to eq(instance.id)
        expect(result.first[:tree_name]).to eq('Published Tree')
        expect(result.first[:excluded]).to eq(tree_element.excluded)
      end
    end

    context 'when instance is only in read-only trees' do
      let(:instance) { create(:instance) }
      let(:tree) { create(:tree, name: 'Read Only Tree', is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id, is_read_only: true)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/readonly/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns empty result' do
        result = instance.in_published_trees
        expect(result).to be_empty
      end
    end

    context 'when instance is not in any trees' do
      let(:instance) { create(:instance) }

      it 'returns empty result' do
        result = instance.in_published_trees
        expect(result).to be_empty
      end
    end

    context 'when multiple published trees contain the instance' do
      let(:instance) { create(:instance) }
      let(:tree_1) { create(:tree, name: 'Published Tree', is_read_only: false) }
      let(:tree_2) { create(:tree, name: 'Second Published Tree', is_read_only: false) }
      let(:tree_version_1) { create(:tree_version, tree: tree_1) }
      let(:tree_version_2) { create(:tree_version, tree: tree_2) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree_1.update!(current_tree_version_id: tree_version_1.id)
        tree_2.update!(current_tree_version_id: tree_version_2.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version_1.id,
          element_link: "test/tree1/#{tree_element.id}",
          taxon_id: tree_element.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version_2.id,
          element_link: "test/tree2/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns all published trees containing the instance' do
        result = instance.in_published_trees

        expect(result.size).to eq(2)
        tree_names = result.map { |r| r[:tree_name] }
        expect(tree_names).to include('Published Tree', 'Second Published Tree')
      end
    end

    context 'when instance is in both read-only and non-read-only trees' do
      let(:instance) { create(:instance) }
      let(:readonly_tree) { create(:tree, name: 'Read Only Tree', is_read_only: false) }
      let(:editable_tree) { create(:tree, name: 'Editable Tree', is_read_only: false) }
      let(:readonly_version) { create(:tree_version, tree: readonly_tree) }
      let(:editable_version) { create(:tree_version, tree: editable_tree) }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        readonly_tree.update!(current_tree_version_id: readonly_version.id, is_read_only: true)
        editable_tree.update!(current_tree_version_id: editable_version.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: readonly_version.id,
          element_link: "test/readonly/#{tree_element.id}",
          taxon_id: tree_element.id)

        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: editable_version.id,
          element_link: "test/editable/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns only non-read-only trees' do
        result = instance.in_published_trees

        expect(result.length).to eq(1)
        expect(result.first[:tree_name]).to eq('Editable Tree')
      end
    end
  end

  describe '.published_trees_map_for' do
    # NOTES: in_published_trees (above) is now just this method called for
    # a single id, so the specs above already cover the underlying query's
    # correctness (published trees only, excluded flag, multiple trees,
    # read-only trees excluded). These specs cover what's new here: batching
    # several instances' published trees into one query, keyed correctly by
    # instance id, and not scaling with the number of instances given.
    let(:tree) { create(:tree, name: 'Published Tree', is_read_only: false) }
    let(:tree_version) { create(:tree_version, tree: tree) }

    def publish_instance_in(instance, tree, tree_version)
      tree.update!(current_tree_version_id: tree_version.id)
      tree_element = create(:tree_element, instance: instance)
      create(:tree_version_element,
        tree_element_id: tree_element.id,
        tree_version_id: tree_version.id,
        element_link: "test/#{tree_element.id}",
        taxon_id: tree_element.id)
    end

    def count_instance_load_queries
      count = 0
      callback = lambda do |*args|
        payload = args.last
        count += 1 if payload[:name] == 'Instance Load'
      end
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
      count
    end

    it 'groups results by instance id, keeping each instance to its own trees' do
      instance_1 = create(:instance)
      instance_2 = create(:instance)
      publish_instance_in(instance_1, tree, tree_version)

      map = Instance.published_trees_map_for([instance_1, instance_2])

      expect(map[instance_1.id].map { |r| r[:tree_name] }).to eq(['Published Tree'])
      expect(map).not_to have_key(instance_2.id)
    end

    it 'accepts plain ids as well as instances' do
      instance = create(:instance)
      publish_instance_in(instance, tree, tree_version)

      map = Instance.published_trees_map_for([instance.id])

      expect(map[instance.id].map { |r| r[:tree_name] }).to eq(['Published Tree'])
    end

    it 'returns an empty hash for an empty list' do
      expect(Instance.published_trees_map_for([])).to eq({})
    end

    it 'fetches every instance in one query, regardless of how many are given' do
      instances = Array.new(5) { create(:instance) }
      instances.each do |i|
        instance_tree = create(:tree, is_read_only: false)
        publish_instance_in(i, instance_tree, create(:tree_version, tree: instance_tree))
      end

      query_count = count_instance_load_queries { Instance.published_trees_map_for(instances) }

      expect(query_count).to eq(1)
    end
  end

  describe '#in_any_local_tree_ids?' do
    let(:instance) { create(:instance) }

    context 'when tree_ids is blank' do
      it 'returns false for empty array' do
        expect(instance.in_any_local_tree_ids?([])).to eq false
      end

      it 'returns false for nil' do
        expect(instance.in_any_local_tree_ids?(nil)).to eq false
      end
    end

    context 'when instance is in one of the provided trees' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:tree_version) { create(:tree_version, tree: tree, draft_name: "In Tree Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/in_tree/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns true' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq true
      end

      it 'returns true when tree is among multiple tree_ids' do
        other_tree = create(:tree)
        expect(instance.in_any_local_tree_ids?([other_tree.id, tree.id])).to eq true
      end
    end

    context 'when instance is not in any of the provided trees' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:other_tree) { create(:tree) }
      let(:tree_version) { create(:tree_version, tree: tree, draft_name: "Not In Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: tree_version.id,
          element_link: "test/not_in/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns false' do
        expect(instance.in_any_local_tree_ids?([other_tree.id])).to eq false
      end
    end

    context 'when instance is not in any trees at all' do
      let(:tree) { create(:tree) }

      it 'returns false' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq false
      end
    end

    context 'when tree version is not current' do
      let(:tree) { create(:tree, is_read_only: false) }
      let(:old_tree_version) { create(:tree_version, tree: tree, draft_name: "Old Draft") }
      let(:current_tree_version) { create(:tree_version, tree: tree, draft_name: "Current Draft") }
      let(:tree_element) { create(:tree_element, instance: instance) }

      before do
        tree.update!(current_tree_version_id: current_tree_version.id)
        create(:tree_version_element,
          tree_element_id: tree_element.id,
          tree_version_id: old_tree_version.id,
          element_link: "test/old/#{tree_element.id}",
          taxon_id: tree_element.id)
      end

      it 'returns false because instance is only in old version' do
        expect(instance.in_any_local_tree_ids?([tree.id])).to eq false
      end
    end
  end
end
