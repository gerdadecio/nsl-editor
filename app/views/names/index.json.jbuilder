# frozen_string_literal: true

json.array!(@names) do |name|
  json.extract!(name, :id)
  json.url(name_url(name, format: :json))
end
