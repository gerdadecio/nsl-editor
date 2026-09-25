# frozen_string_literal: true

json.array!(@instance_notes) do |instance_note|
  json.extract!(instance_note, :id)
  json.url(instance_note_url(instance_note, format: :json))
end
