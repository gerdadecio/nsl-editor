# frozen_string_literal: true

class Tabs::Permissions::Default::ReferencesPermissionService < Tabs::Permissions::BasePermissionService
  def execute
    return unless valid?
    @result = self
  end

  protected

  def resource_type_key
    'reference'
  end
end