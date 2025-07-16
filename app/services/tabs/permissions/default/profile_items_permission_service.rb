# frozen_string_literal: true

class Tabs::Permissions::Default::ProfileItemsPermissionService < Tabs::Permissions::BasePermissionService
  def execute
    return unless valid?
    @result = self
  end

  protected

  def resource_type_key
    'profile_items'
  end
end