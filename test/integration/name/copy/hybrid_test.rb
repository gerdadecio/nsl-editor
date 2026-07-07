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

# Exercises the "copy a hybrid name" workflow that the copy form drives:
# POST names/:id/copy with a new element and two chosen parents.
class NamesCopyHybridTest < ActionController::TestCase
  tests NamesController

  def setup
    @source = names(:hybrid_formula) # parent: a_species, second_parent: another_species
    # New parents, distinct from the source's own parents (the form requires this).
    @new_first_parent = names(:triodia_basedowii)
    @new_second_parent = names(:crotalaria_distans)
    @edit_session = { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] }
  end

  def post_copy(name_element:, parent_id:, second_parent_id:)
    post(:copy,
         params: { name: { "name_element" => name_element,
                           "name_rank_id" => @source.name_rank_id.to_s,
                           "parent_id" => parent_id.to_s,
                           "second_parent_id" => second_parent_id.to_s },
                   format: :js,
                   "id" => @source.id.to_s },
         session: @edit_session)
  end

  test "copying a hybrid name creates a new name with [n/a] status and the chosen parents" do
    new_name = nil

    Name.stub_any_instance(:set_names!, nil) do
      Name.stub_any_instance(:refresh_name_paths, 0) do
        assert_difference("Name.count", 1) do
          post_copy(name_element: "hybrid copy",
                    parent_id: @new_first_parent.id,
                    second_parent_id: @new_second_parent.id)
        end
        new_name = Name.find_by(name_element: "hybrid copy")
      end
    end

    assert_not_nil new_name, "the copied name should have been created"
    assert_equal "[n/a]", new_name.name_status.name
    assert_equal @new_first_parent.id, new_name.parent_id
    assert_equal @new_second_parent.id, new_name.second_parent_id
  end

  test "copying a hybrid name reusing the original's first parent does not create a new name" do
    assert_difference("Name.count", 0) do
      post_copy(name_element: "hybrid copy",
                parent_id: @source.parent_id,
                second_parent_id: @new_second_parent.id)
    end
  end

  test "copying a hybrid name reusing the original's second parent does not create a new name" do
    assert_difference("Name.count", 0) do
      post_copy(name_element: "hybrid copy",
                parent_id: @new_first_parent.id,
                second_parent_id: @source.second_parent_id)
    end
  end
end
