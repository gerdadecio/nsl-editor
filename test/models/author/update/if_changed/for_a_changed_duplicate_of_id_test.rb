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
class ForAChangedDuplicateOfIdTest < ActiveSupport::TestCase
  def setup
    @author = Author::AsEdited.find(authors(:haeckel).id)
    form_params = ActiveSupport::HashWithIndifferentAccess.new
    form_params[:duplicate_of_id] = authors(:brongn).id
    form_params[:duplicate_of_typeahead] = authors(:brongn).name
    @author.update_if_changed(
      {},
      form_params,
      "a user"
    )
  end

  test "changed duplicate of id" do
    changed_author = Author.find_by(id: @author.id)
    assert_equal authors(:brongn).id,
                 changed_author.duplicate_of_id,
                 "Duplicate of id should have changed to the new value"
    assert_match "a user",
                 changed_author.updated_by,
                 "Author.updated_by should have changed to the updating user"
    assert @author.created_at < changed_author.updated_at,
           "Author updated at should have changed."
  end
end
