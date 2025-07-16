# frozen_string_literal: true

class Tabs::Permissions::Registry
  PERMISSIONS = {
    'name' => {
      'tab_edit' => { ability: 'names', action: 'update' },
      'tab_instances_profile_v2' => { ability: :create_with_product_reference, resource: 'Instance' },
      'tab_instances' => { 
        ability: :create, 
        resource: 'Instance',
        exclude: { ability: :create_with_product_reference, resource: 'Instance' }
      },
      'tab_copy' => { ability: :create, resource: 'Instance' },
      'tab_delete' => { ability: 'names', action: 'delete' },
      'tab_more' => { ability: 'names', action: 'update' }
    },
    'reference' => {
      'tab_edit_1' => { ability: :update, resource: '@resource' },
      'tab_edit_2' => { ability: :update, resource: '@resource' },
      'tab_edit_3' => { ability: :update, resource: '@resource' },
      'tab_comments' => { ability: 'comments', action: 'create' },
      'tab_new_instance' => { ability: 'instances', action: 'create' },
      'tab_copy' => { ability: 'references', action: 'copy' }
    },
    'instances' => {
      'tab_show_1' => { ability: 'instances', action: 'tab_show_1' },
      'tab_edit' => { ability: :edit, resource: '@resource' },
      'tab_edit_profile_v2' => { ability: :manage_draft_secondary_reference, resource: '@resource' },
      'tab_edit_notes' => { ability: 'instance_notes', action: 'edit' },
      'tab_synonymy' => { ability: :create, resource: 'Instance' },
      'tab_synonymy_for_profile_v2' => { ability: :synonymy_as_draft_secondary_reference, resource: '@resource' },
      'tab_unpublished_citation' => { ability: :create, resource: '@resource' },
      'tab_unpublished_citation_for_profile_v2' => { ability: :unpublished_citation_as_draft_secondary_reference, resource: '@resource' },
      'tab_classification' => { ability: 'classification', action: 'place' },
      'tab_comments' => { ability: 'comments', action: 'create' },
      'tab_copy_to_new_reference' => { ability: 'instances', action: 'copy_standalone' },
      'tab_copy_to_new_profile_v2' => { ability: :copy_as_draft_secondary_reference, resource: 'Instance' },
      'tab_profile_details' => { ability: 'classification', action: 'place' },
      'tab_edit_profile' => { ability: 'classification', action: 'place' },
      'tab_batch_loader' => { ability: 'loader/batches', action: 'process' },
      'tab_batch_loader_2' => { 
        ability: 'loader/batches', 
        action: 'process',
        additional: { ability: 'loader/instances-loader-2', action: 'use' }
      },
      'tab_profile_v2' => { ability: :manage_profile, resource: '@resource' }
    },
    'profile_items' => {
      'tab_edit' => { ability: :manage, resource: '@resource' }
    }
  }.freeze

  def self.permission_for(resource_type, tab_id)
    PERMISSIONS.dig(resource_type.to_s, tab_id.to_s)
  end

  def self.has_permission?(resource_type, tab_id)
    PERMISSIONS.dig(resource_type.to_s, tab_id.to_s).present?
  end

  def self.resource_types
    PERMISSIONS.keys
  end

  def self.tabs_for_resource(resource_type)
    PERMISSIONS[resource_type.to_s]&.keys || []
  end
end