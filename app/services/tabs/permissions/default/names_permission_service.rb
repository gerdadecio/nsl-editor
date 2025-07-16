# frozen_string_literal: true

class Tabs::Permissions::Default::NamesPermissionService < Tabs::Permissions::BasePermissionService
  def execute
    return unless valid?
    @result = self # Return service instance for tab checking
  end

  protected

  def resource_type_key
    'name'
  end
end