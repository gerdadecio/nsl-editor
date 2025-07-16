# frozen_string_literal: true

module Tabs
  module Permissions
    module Products
      module Foa
        class NamesPermissionService < ::Tabs::Permissions::Default::NamesPermissionService
          # FOA (Flora of Australia) specific permission overrides for names

          # Example: Override specific tab permissions when FOA differs from default
          # def can_show_tab_edit?
          #   # FOA-specific logic for edit tab
          #   super && additional_foa_check?
          # end

          # def can_show_tab_copy?
          #   # FOA might have different copy permissions
          #   super && user_has_foa_copy_rights?
          # end

          private

          # def additional_foa_check?
          #   # FOA-specific permission logic
          #   true
          # end

          # def user_has_foa_copy_rights?
          #   # Check FOA-specific copy permissions
          #   @session_user.can?(:copy_foa_names)
          # end
        end
      end
    end
  end
end
