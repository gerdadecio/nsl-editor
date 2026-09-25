# frozen_string_literal: true

FactoryBot.define do
  factory :current_tve do
    updated_by { "Sample Updated by" }
    merge_conflict { true }
  end
end
