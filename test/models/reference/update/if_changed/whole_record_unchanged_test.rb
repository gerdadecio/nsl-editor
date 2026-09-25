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
require "test_helper"

# Single Reference model test.
class WholeRecordUnchangedTest < ActiveSupport::TestCase
  test "realistic form submission with no change" do
    reference = Reference::AsEdited.find(
      references(:for_whole_record_change_detection).id,
    )

    params = {
      "title" => reference.title,
      "iso_publication_date" => reference.iso_publication_date,
      "volume" => reference.volume,
      "pages" => reference.pages,
      "edition" => reference.edition,
      "ref_author_role_id" => reference.ref_author_role_id,
      # the rails log shows published coming as '1' when true
      "published" => reference.published ? "1" : "0",
      "publication_date" => reference.publication_date,
      "notes" => reference.notes,
      "ref_type_id" => reference.ref_type_id,
    }

    typeahead_params = {
      "parent_id" => reference.parent_id,
      "parent_typeahead" => reference.parent.citation,
      "author_id" => reference.author_id,
      "author_typeahead" => reference.author.name,
    }

    assert reference.update_if_changed(params, typeahead_params, "a user")
    changed_reference = Reference.find_by(id: reference.id)
    assert_equal reference.created_at,
      changed_reference.updated_at,
      "Reference should not have been updated."
  end
end
