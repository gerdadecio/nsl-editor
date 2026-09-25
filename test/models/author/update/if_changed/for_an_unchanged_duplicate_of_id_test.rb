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

# Single author model test.
class ForAnUnchangedDuplicateOfIdTest < ActiveSupport::TestCase
  def setup
    @author = Author::AsEdited.find(authors(:is_a_duplicate_of_that_is_all).id)
    @author.update_if_changed(
      {},
      {
        duplicate_of_id: authors(:has_one_duplicate_that_is_all).id,
        duplicate_of_typeahead: authors(:has_one_duplicate_that_is_all).name,
      },
      "a user",
    )
  end

  test "unchanged duplicate of id" do
    changed_author = Author.find_by(id: @author.id)
    assert_equal @author.duplicate_of_id,
      changed_author.duplicate_of_id,
      "Duplicate of id should not have changed"
    assert_equal @author.created_at,
      changed_author.updated_at,
      "Author should not have been updated."
  end
end
