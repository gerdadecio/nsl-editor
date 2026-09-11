# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Helpers for the admin page.
module AdminHelper
  DEFAULT_SERVICES_PRODUCT = "apni"

  # Product segment used in the sample client-side service URLs.
  def admin_services_product
    Rails.configuration.try(:services_product).presence || DEFAULT_SERVICES_PRODUCT
  end

  # A sample name id for the service URLs on the admin page.
  #
  # The id comes from the database, so it is coerced to an Integer before it is
  # interpolated into a URL that the page renders. That guarantees the value can
  # only ever be digits, regardless of what is stored in the table.
  def admin_sample_name_id
    Integer(Name.minimum(:id) || 0)
  end

  def admin_sample_reference_id
    Integer(Reference.minimum(:id) || 0)
  end

  # Build a sample client-side services URL for the admin page.
  #
  #   admin_service_url("name", "apc.json")
  #   => "https://services.example/rest/name/apni/123/api/apc.json"
  def admin_service_url(resource, endpoint)
    root = Rails.configuration.try(:services_clientside_root_url).to_s
    "#{root}rest/#{resource}/#{admin_services_product}/#{admin_sample_name_id}/api/#{endpoint}"
  end

  def admin_service_reference_url(resource, endpoint)
    root = Rails.configuration.try(:services_clientside_root_url).to_s
    "#{root}rest/#{resource}/#{admin_services_product}/#{admin_sample_reference_id}/api/#{endpoint}"
  end
end
