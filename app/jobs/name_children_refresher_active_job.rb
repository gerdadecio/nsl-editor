# ActiveJob version to refresh names - Rails 8.0 compatible.
class NameChildrenRefresherActiveJob < ApplicationJob
  def perform(name_id)
    names_refreshed = 0
    npaths_refreshed = 0
    Rails.logger.info("NameChildrenRefresherActiveJob - an ActiveJob.")
    Rails.logger.info("May be asynchronous")
    
    # ActiveJob handles database connections automatically
    name = Name.find(name_id)
    names_refreshed = name.refresh_tree
    npaths_refreshed = name.refresh_name_paths
    names_refreshed
  end
end