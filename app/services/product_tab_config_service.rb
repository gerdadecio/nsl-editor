# frozen_string_literal: true

class ProductTabConfigService < BaseService
  CONFIG_FILE = Rails.root.join('config', 'product_tabs.json').freeze

  validate :validate_params

  attr_reader :user, :session_user, :resource_type, :resource, :tabs_to_offer, :product_name, :result

  def initialize(user:, session_user:, resource_type:, resource: nil, tabs_to_offer: nil)
    super({})
    @user = user
    @session_user = session_user
    @resource_type = resource_type
    @resource = resource
    @tabs_to_offer = tabs_to_offer
    @product_name = user&.available_product_from_roles&.name
    load_configuration
  end

  def execute
    return unless valid?
    @result = get_accessible_tabs_config
  end

  def get_tab_label(product_name, resource_type, tab_type)
    product_config = configuration.dig('products', product_name&.upcase) ||
                    configuration.dig('products', 'default')

    return nil unless product_config

    resource_config = product_config[resource_type.to_s]
    return nil unless resource_config

    resource_config[tab_type.to_s]
  end

  def get_tab_label_with_fallback(product_name, resource_type, tab_type, fallback = nil)
    label = get_tab_label(product_name, resource_type, tab_type)
    return label if label

    if product_name&.upcase != 'DEFAULT'
      label = get_tab_label('default', resource_type, tab_type)
      return label if label
    end

    fallback || tab_type.to_s.humanize
  end

  def get_tabs_config(product_name, resource_type)
    product_config = configuration.dig('products', product_name&.upcase) ||
                    configuration.dig('products', 'default')

    return [] unless product_config

    resource_config = product_config[resource_type.to_s]
    return [] unless resource_config

    tabs = resource_config['tabs'] || []

    tabs.map do |tab|
      tab.transform_keys { |key| key.to_sym }
    end
  end

  def get_accessible_tabs_config
    tabs = get_tabs_config(product_name, resource_type)
    return [] if tabs.empty?

    tabs.select do |tab|
      should_show_tab?(tab)
    end
  end

  private

  attr_reader :configuration

  def validate_params
    errors.add(:user, "User is required") if user.nil?
    errors.add(:resource_type, "Resource type is required") if resource_type.blank?
  end

  def should_show_tab?(tab)
    if tabs_to_offer&.is_a?(Array)
      return false unless tabs_to_offer.include?(tab[:id])
    end

    permission_service = get_permission_service
    return true unless permission_service

    permission_service.can_show_tab?(tab[:id])
  end

  def get_permission_service
    return @permission_service if defined?(@permission_service)

    resolver_service = Tabs::Permissions::PermissionResolverService.call(
      product: product_name,
      resource_type: resource_type,
      session_user: session_user,
      resource: resource
    )

    if resolver_service.errors.any?
      Rails.logger.error "Permission resolver errors: #{resolver_service.errors.full_messages}"
      @permission_service = nil
      return nil
    end

    @permission_service = resolver_service.result
  end

  def load_configuration
    @configuration = JSON.parse(File.read(CONFIG_FILE))
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse product tabs configuration: #{e.message}"
    @configuration = default_configuration
  rescue Errno::ENOENT => e
    Rails.logger.error "Product tabs configuration file not found: #{e.message}"
    @configuration = default_configuration
  end

  def default_configuration
    {
      'products' => {
        'default' => {
          'name' => {
            'edit' => 'Edit',
            'copy' => 'Copy',
            'synonymy' => 'Synonymy',
            'unpublished_citation' => 'Unpublished Citation'
          },
          'instance' => {
            'edit' => 'Edit Instance',
            'copy' => 'Copy Instance',
            'synonymy' => 'Instance Synonymy',
            'unpublished_citation' => 'Instance Unpublished Citation'
          },
          'reference' => {
            'edit' => 'Edit Reference',
            'copy' => 'Copy Reference'
          }
        }
      }
    }
  end
end
