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

# Single controller test.
#
# The stub's response block deletes the fixture row itself, simulating the
# external Name Services app deleting the same underlying row before it
# responds. This is the genuine-success case: the service says ok, and the
# name really is gone.
class NamesDeleteConfirmForEditorRendersOkWhenNameIsActuallyGoneTest < ActionController::TestCase
  tests NamesDeletesController

  setup do
    @name = names(:name_to_delete)
    @reason = "some reason"
    @extra_info = ""
    stub_it
  end

  def a
    "http://localhost:9090/nsl/services/rest/name/apni/#{@name.id}/api/delete"
  end

  def b
    "?apiKey=test-api-key&reason=#{@reason}"
  end

  def stub_it
    name_id = @name.id
    stub_request(:delete, "#{a}#{b}")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090"})
      .to_return do |_request|
        Name.delete(name_id)
        { status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" } }
      end
  end

  test "renders ok and the name is gone when the service really deletes it" do
    @request.headers["Accept"] = "application/javascript"
    delete(:confirm,
           params: { names_delete: { name_id: @name.id,
                                     reason: @reason,
                                     extra_info: @extra_info } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    assert_response :success
    assert_includes @response.body, "Record deleted"
    assert_not Name.exists?(@name.id)
  end
end
