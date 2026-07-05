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

# Instance Notes controller tests.
class InstanceNotesControllerTest < ActionController::TestCase
  setup do
    @instance_note = instance_notes(:one)
  end

  test "instance notes index should route to the catch-all" do
    assert_routing "/instance_notes",
                   controller: "search",
                   action: "search",
                   random: "instance_notes"
  end

  test "instance notes new should route to a new instance note" do
    assert_routing "/instance_notes/new",
                   controller: "instance_notes",
                   action: "new"
  end

  test "should get new" do
    @request.headers["Accept"] = "application/javascript"
    get :new
    assert_response :success
  end

  # test "instance notes create should route to create an instance note" do
  # assert_routing '/instance_notes/create',
  # { controller: "instance_notes", action: "create", method: "post"}
  # end

  test "should create instance note" do
    @request.headers["Accept"] = "application/javascript"
    assert_difference("InstanceNote.count") do
      post(:create,
           params: { instance_note:
                     { "instance_id" => instances(:triodia_in_brassard),
                       "instance_note_key_id" => instance_note_keys(:neotype),
                       "value" => "this is a note" } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    end
  end

  test "should show instance_note" do
    @request.headers["Accept"] = "application/javascript"
    get :show,
        params: { id: @instance_note }
    assert_response :success
  end

  test "should get edit" do
    @request.headers["Accept"] = "application/javascript"
    get :edit,
        params: { id: @instance_note }
    assert_response :success
  end

  # test "should update instance_note" do
  # @request.headers["Accept"] = "application/javascript"
  # patch :update, id: @instance_note, instance_note: {  }
  # assert_redirected_to instance_note_path(assigns(:instance_note))
  # end

  # test "should destroy instance_note" do
  # @request.headers["Accept"] = "application/javascript"
  # assert_difference('InstanceNote.count', -1) do
  # delete :destroy, id: @instance_note
  # end
  ##     assert_redirected_to instance_notes_path
  # end
end
