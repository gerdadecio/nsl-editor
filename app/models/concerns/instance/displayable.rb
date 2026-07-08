# frozen_string_literal: true

module Instance::Displayable
  extend ActiveSupport::Concern

  def needs_a_comma?
    page.present? ||
      (name.name_status.present? &&
       name.name_status.name_for_instance_display.present?)
  end
end
