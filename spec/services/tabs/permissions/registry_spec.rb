require 'rails_helper'

RSpec.describe Tabs::Permissions::Registry, type: :service do
  describe '.permission_for' do
    context 'with valid resource type and tab id' do
      it 'returns permission for name tab_details' do
        permission = described_class.permission_for('name', 'tab_details')
        expect(permission).to eq({})
      end

      it 'returns permission for name tab_edit' do
        permission = described_class.permission_for('name', 'tab_edit')
        expect(permission).to eq({ ability: 'names', action: 'update' })
      end

      it 'returns permission for name tab_instances_profile_v2' do
        permission = described_class.permission_for('name', 'tab_instances_profile_v2')
        expect(permission).to eq({ ability: :create_with_product_reference, resource: 'Instance' })
      end

      it 'returns permission for name tab_instances with exclude' do
        permission = described_class.permission_for('name', 'tab_instances')
        expected = {
          ability: :create,
          resource: 'Instance',
          exclude: { ability: :create_with_product_reference, resource: 'Instance' }
        }
        expect(permission).to eq(expected)
      end

      it 'returns permission for reference tab_show_1' do
        permission = described_class.permission_for('reference', 'tab_show_1')
        expect(permission).to eq({})
      end

      it 'returns permission for reference tab_edit_1' do
        permission = described_class.permission_for('reference', 'tab_edit_1')
        expect(permission).to eq({ ability: :update, resource: '@resource' })
      end

      it 'returns permission for instances tab_batch_loader_2 with additional' do
        permission = described_class.permission_for('instances', 'tab_batch_loader_2')
        expected = {
          ability: 'loader/batches',
          action: 'process',
          additional: { ability: 'loader/instances-loader-2', action: 'use' }
        }
        expect(permission).to eq(expected)
      end

      it 'returns permission for profile_items tab_show_1' do
        permission = described_class.permission_for('profile_items', 'tab_show_1')
        expect(permission).to eq({})
      end

      it 'returns permission for profile_items tab_edit' do
        permission = described_class.permission_for('profile_items', 'tab_edit')
        expect(permission).to eq({ ability: :manage, resource: '@resource' })
      end
    end

    context 'with invalid resource type' do
      it 'returns nil for non-existent resource type' do
        permission = described_class.permission_for('invalid_resource', 'tab_edit')
        expect(permission).to be_nil
      end
    end

    context 'with invalid tab id' do
      it 'returns nil for non-existent tab id' do
        permission = described_class.permission_for('name', 'invalid_tab')
        expect(permission).to be_nil
      end
    end

    context 'with string and symbol conversion' do
      it 'handles string resource type' do
        permission = described_class.permission_for('name', 'tab_edit')
        expect(permission).to eq({ ability: 'names', action: 'update' })
      end

      it 'handles symbol resource type' do
        permission = described_class.permission_for(:name, 'tab_edit')
        expect(permission).to eq({ ability: 'names', action: 'update' })
      end

      it 'handles symbol tab id' do
        permission = described_class.permission_for('name', :tab_edit)
        expect(permission).to eq({ ability: 'names', action: 'update' })
      end
    end
  end

  describe '.has_permission?' do
    context 'with existing permission' do
      it 'returns true for tab with permission' do
        result = described_class.has_permission?('name', 'tab_edit')
        expect(result).to be true
      end

      it 'returns true for tab with empty permission hash' do
        result = described_class.has_permission?('name', 'tab_details')
        expect(result).to be true
      end
    end

    context 'with non-existing permission' do
      it 'returns false for invalid resource type' do
        result = described_class.has_permission?('invalid_resource', 'tab_edit')
        expect(result).to be false
      end

      it 'returns false for invalid tab id' do
        result = described_class.has_permission?('name', 'invalid_tab')
        expect(result).to be false
      end
    end

    context 'with string and symbol conversion' do
      it 'handles string resource type' do
        result = described_class.has_permission?('name', 'tab_edit')
        expect(result).to be true
      end

      it 'handles symbol resource type' do
        result = described_class.has_permission?(:name, 'tab_edit')
        expect(result).to be true
      end

      it 'handles symbol tab id' do
        result = described_class.has_permission?('name', :tab_edit)
        expect(result).to be true
      end
    end
  end

  describe '.resource_types' do
    it 'returns all resource types' do
      resource_types = described_class.resource_types
      expect(resource_types).to contain_exactly('name', 'reference', 'instances', 'profile_items')
    end
  end

  describe '.tabs_for_resource' do
    context 'with valid resource type' do
      it 'returns tabs for name resource' do
        tabs = described_class.tabs_for_resource('name')
        expected_tabs = [
          'tab_details', 'tab_edit', 'tab_instances_profile_v2', 'tab_instances',
          'tab_copy', 'tab_delete', 'tab_more'
        ]
        expect(tabs).to contain_exactly(*expected_tabs)
      end

      it 'returns tabs for reference resource' do
        tabs = described_class.tabs_for_resource('reference')
        expected_tabs = [
          'tab_show_1', 'tab_edit_1', 'tab_edit_2', 'tab_edit_3',
          'tab_comments', 'tab_new_instance', 'tab_copy'
        ]
        expect(tabs).to contain_exactly(*expected_tabs)
      end

      it 'returns tabs for instances resource' do
        tabs = described_class.tabs_for_resource('instances')
        expected_tabs = [
          'tab_show_1', 'tab_edit', 'tab_edit_profile_v2', 'tab_edit_notes',
          'tab_synonymy', 'tab_synonymy_for_profile_v2', 'tab_unpublished_citation',
          'tab_unpublished_citation_for_profile_v2', 'tab_classification',
          'tab_comments', 'tab_copy_to_new_reference', 'tab_copy_to_new_profile_v2',
          'tab_profile_details', 'tab_edit_profile', 'tab_batch_loader',
          'tab_batch_loader_2', 'tab_profile_v2'
        ]
        expect(tabs).to contain_exactly(*expected_tabs)
      end

      it 'returns tabs for profile_items resource' do
        tabs = described_class.tabs_for_resource('profile_items')
        expect(tabs).to contain_exactly('tab_show_1', 'tab_edit')
      end
    end

    context 'with invalid resource type' do
      it 'returns empty array for non-existent resource type' do
        tabs = described_class.tabs_for_resource('invalid_resource')
        expect(tabs).to eq([])
      end
    end

    context 'with string and symbol conversion' do
      it 'handles string resource type' do
        tabs = described_class.tabs_for_resource('name')
        expect(tabs).to be_an(Array)
        expect(tabs).not_to be_empty
      end

      it 'handles symbol resource type' do
        tabs = described_class.tabs_for_resource(:name)
        expect(tabs).to be_an(Array)
        expect(tabs).not_to be_empty
      end
    end
  end

  describe 'PERMISSIONS constant' do
    it 'is frozen' do
      expect(described_class::PERMISSIONS).to be_frozen
    end

    it 'contains expected structure' do
      expect(described_class::PERMISSIONS).to be_a(Hash)
      expect(described_class::PERMISSIONS.keys).to contain_exactly('name', 'reference', 'instances', 'profile_items')
      
      described_class::PERMISSIONS.each do |resource_type, tabs|
        expect(tabs).to be_a(Hash)
        tabs.each do |tab_id, permission|
          expect(tab_id).to be_a(String)
          expect(permission).to be_a(Hash)
        end
      end
    end
  end
end