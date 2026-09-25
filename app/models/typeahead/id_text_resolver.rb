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
#   Identify an author entered into or selected into a typeahead.
class Typeahead::IdTextResolver
  attr_reader :result

  NO_ID_OR_TEXT = :no_id_or_text
  ID_AND_TEXT = :id_and_text
  ID_ONLY = :id_only
  TEXT_ONLY = :text_only

  def initialize(id_string, text)
    @id_string = id_string
    @text = text
    @result = if id_string.blank?
      no_id
    else
      id_present # assume intention is to remove the field value
    end
  end

  def no_id
    if @text.blank?
      NO_ID_OR_TEXT
    else # @text.present?
      TEXT_ONLY
    end
  end

  def id_present
    if @text.blank?
      ID_ONLY # assume intention is to remove the field value
    else # @text.present?
      ID_AND_TEXT
    end
  end
end
