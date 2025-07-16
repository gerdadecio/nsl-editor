# frozen_string_literal: true

module Tabs
  module Permissions
    module Products
      module Apc
        class ReferencesPermissionService < ::Tabs::Permissions::Default::ReferencesPermissionService
          # APC (Australian Plant Census) specific permission overrides for references

          # Example: Override specific tab permissions when APC differs from default
          # def can_show_tab_edit_1?
          #   # APC-specific logic for edit tab
          #   super && apc_editing_allowed?
          # end

          # def can_show_tab_copy?
          #   # APC might have stricter copy permissions
          #   super && @session_user.can?(:copy_apc_references)
          # end

          private

          # def apc_editing_allowed?
          #   # APC-specific permission logic
          #   @session_user.can?(:edit_apc_content)
          # end
        end
      end
    end
  end
end
