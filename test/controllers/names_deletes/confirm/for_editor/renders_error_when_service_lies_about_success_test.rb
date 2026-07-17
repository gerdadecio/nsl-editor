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
# Regression test: the external Name Services delete API can respond with
# HTTP 200 and {"ok": true} even when it did not actually delete the name
# (see the comment on Name::AsServices#delete_with_reason). Unlike the
# genuine-success case, this stub's response block does NOT delete the
# fixture row, simulating the service lying about success.
# NamesDeletesController#name_is_gone? must catch this and report an error
# rather than telling the user the name was deleted.
class NamesDeleteConfirmForEditorRendersErrorWhenServiceLiesAboutSuccessTest < ActionController::TestCase
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
    stub_request(:delete, "#{a}#{b}")
      .with(headers: { "Accept" => "application/json",
                       "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                       "Host" => "localhost:9090"})
      .to_return(status: 200, body: '{"ok": true}', headers: { "Content-Type" => "application/json" })
  end

  test "renders an error and does not claim success when the service says ok but the name is still there" do
    @request.headers["Accept"] = "application/javascript"
    delete(:confirm,
           params: { names_delete: { name_id: @name.id,
                                     reason: @reason,
                                     extra_info: @extra_info } },
           session: { username: "fred",
                      user_full_name: "Fred Jones",
                      groups: ["edit"] })
    assert_response :success
    assert_includes @response.body, "Name not deleted"
    assert_not_includes @response.body, "Record deleted"
    assert Name.exists?(@name.id), "Name should still exist - the service did not really delete it"
  end
end
