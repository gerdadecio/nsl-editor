# frozen_string_literal: true

class Tabs::Permissions::BasePermissionService < BaseService
  validate :validate_params

  attr_reader :user, :resource, :result

  def initialize(user:, resource: nil)
    super({})
    @user = user
    @resource = resource
  end

  def execute
    return unless valid?

    @result = self
  end

  def can_show_tab?(tab_id)
    return true if tab_id.blank?

    permission = registry.permission_for(resource_type_key, tab_id)
    return true unless permission

    evaluate_permission(permission)
  end

  protected

  def resource_type_key
    raise NotImplementedError, "Subclasses must implement resource_type_key method"
  end

  def registry
    Tabs::Permissions::Registry
  end

  private

  def validate_params
    errors.add(:user, "User is required") if user.nil?
  end

  def evaluate_permission(permission)
    main_permission_granted = has_main_permission?(permission)

    if permission[:exclude]
      return main_permission_granted && !has_exclude_permission?(permission[:exclude])
    end

    if permission[:additional]
      return main_permission_granted && has_additional_permission?(permission[:additional])
    end

    main_permission_granted
  end

  def has_main_permission?(permission)
    check_permission(permission)
  end

  def has_exclude_permission?(exclude_permission)
    check_permission(exclude_permission)
  end

  def has_additional_permission?(additional_permission)
    check_permission(additional_permission)
  end

  def check_permission(permission)
    if permission[:resource] == '@resource'
      return false unless @resource
      @user.can?(permission[:ability], @resource)
    elsif permission[:resource]
      resource_class = permission[:resource].constantize
      @user.can?(permission[:ability], resource_class)
    elsif permission[:action]
      @user.can?(permission[:ability], permission[:action])
    else
      @user.can?(permission[:ability])
    end
  rescue NameError => e
    Rails.logger.error "Permission check failed: #{e.message} for permission: #{permission}"
    false
  end
end
