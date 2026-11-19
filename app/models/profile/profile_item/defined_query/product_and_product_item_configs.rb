# frozen_string_literal: true

class Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs
  attr_reader :product,
    :instance,
    :product_configs_and_profile_items

  def initialize(session_user, instance, params = {})
    @params = params
    @session_user = session_user
    @user = session_user.user
    @product = find_product
    @product_configs_and_profile_items = []
    @instance = instance
  end

  def debug(s)
    tag = "Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs"
    Rails.logger.debug { "#{tag}: #{s}" }
  end

  def run_query
    debug("run_query")
    @product_configs_and_profile_items = find_or_initialize_profile_items if profile_v2_aware?

    [ product_configs_and_profile_items, product ]
  end

  private

  attr_reader :user, :params

  # An explicit product_name param wins. Otherwise use the product the
  # session is working in (the one the abilities check), as long as the user
  # has a role on it and it manages profiles. Without a context, fall back to
  # the user's first product that manages profiles.
  def find_product
    return user.products.find_by(name: params[:product_name]) if params.dig(:product_name).present?

    context_product = @session_user.product_from_context
    return context_product if context_product&.manages_profile? && user.products.include?(context_product)

    user.products.where(manages_profile: true).first
  end

  def profile_v2_aware?
    Rails.configuration.try("profile_v2_aware")
  end

  def find_or_initialize_profile_items
    return [] if @product.nil? || @instance.nil?

    product_item_configs = fetch_product_item_configs

    existing_profile_items = fetch_existing_profile_items(product_item_configs)

    map_product_item_configs_to_profile_items(product_item_configs, existing_profile_items)
  end

  def fetch_product_item_configs
    query = base_query
    filter_by_config_id(query)
  end

  def base_query
    Profile::ProductItemConfig
      .where(product_id: @product.id)
      .joins(profile_item_type: :profile_object_type)
      .where(profile_object_type: { rdf_id: @params[:rdf_id] || "text" })
      .where.not(display_html: nil)
  end

  def filter_by_config_id(query)
    return query unless @params[:product_item_config_id]

    query.where(id: @params[:product_item_config_id])
  end

  def fetch_existing_profile_items(product_item_configs)
    items = Profile::ProfileItem
      .where(
        product_item_config_id: product_item_configs.select(:id),
        instance_id: @instance.id,
        end_date: nil,
      )
      .includes(
        :sourced_in_profile_items,
        :profile_item_annotation,
        :profile_item_references,
        :profile_text,
      )
      .order(created_at: :desc)

    return items if params[:all]

    group_items_by_config(items)
  end

  def group_items_by_config(items)
    items
      .group_by(&:product_item_config_id)
      .transform_values(&:first)
  end

  def map_product_item_configs_to_profile_items(product_item_configs, existing_profile_items)
    product_item_configs.map do |product_item_config|
      profile_item = find_or_initialize_profile_item(
        product_item_config,
        existing_profile_items[product_item_config.id],
      )

      { product_item_config: product_item_config, profile_item: profile_item }
    end
  end

  def find_or_initialize_profile_item(product_item_config, existing_profile_item)
    return existing_profile_item if existing_profile_item

    Profile::ProfileItem.new(
      product_item_config: product_item_config,
      instance_id: @instance.id,
    )
  end
end
