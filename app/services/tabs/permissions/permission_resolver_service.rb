# frozen_string_literal: true

class Tabs::Permissions::PermissionResolverService < BaseService
  validate :validate_params

  attr_reader :product, :resource_type, :session_user, :resource, :result

  RESOURCE_NAMES = {
    name: "Names",
    reference: "References",
    instances: "Instances",
    instance: "Instances",
    profile_items: "ProfileItems",
    profile_item: "ProfileItems"
  }.freeze

  def initialize(product:, resource_type:, session_user:, resource: nil)
    super({})
    @product = product
    @resource_type = resource_type
    @session_user = session_user
    @resource = resource
  end

  def execute
    return unless valid?
    @result = resolve_permission_service
  end

  private

  def validate_params
    errors.add(:session_user, "SessionUser is required") if session_user.nil?
    errors.add(:resource_type, "Resource type is required") if resource_type.blank?
  end

  def resolve_permission_service
    if product_specific_service_exists?
      build_product_service
    else
      build_default_service
    end
  end

  def product_specific_service_exists?
    return false if product.blank?

    class_name = product_service_class_name
    begin
      Object.const_get(class_name)
      true
    rescue NameError
      false
    end
  end

  def build_product_service
    service_class = product_service_class_name.constantize
    service = service_class.call(session_user: session_user, resource: resource)

    if service.errors.any?
      Rails.logger.error "Product permission service errors: #{service.errors.full_messages}"
      return build_default_service
    end

    service.result
  end

  def build_default_service
    service_class = default_service_class_name.constantize
    service = service_class.call(session_user: session_user, resource: resource)

    if service.errors.any?
      Rails.logger.error "Default permission service errors: #{service.errors.full_messages}"
      return nil
    end

    service.result
  end

  def product_service_class_name
    "Tabs::Permissions::Products::#{normalize_product_name&.titleize}::#{normalize_resource_name}PermissionService"
  end

  def default_service_class_name
    "Tabs::Permissions::Default::#{normalize_resource_name}PermissionService"
  end

  def normalize_product_name
    product.to_s.upcase
  end

  def normalize_resource_name
    RESOURCE_NAMES[resource_type.to_s.downcase] || resource_type.to_s.classify.pluralize
  end
end
