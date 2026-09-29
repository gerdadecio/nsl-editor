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

# Single instance model test.
class InstanceUpdateBHLURLNoUpdateForEmptyStringTest < ActiveSupport::TestCase
  def setup
    @unchanged = instances(:has_no_page_bhl_url_verbatim_name_string)
    @instance = Instance::AsEdited.find(@unchanged.id)
  end

  test "bhl url no update for empty string" do
    assert @unchanged.page.blank?, "Page should be blank for this test."
    assert @unchanged.bhl_url.blank?, "BHL URL should be blank for this test."
    message = @instance.update_if_changed({ "bhl_url" => "" }, "fred")
    assert message.start_with?("No change"),
           "Message should be 'No change' not '#{message}'"
    assert @instance.bhl_url.blank?, "BHL URL should still be blank."
    assert @instance.updated_at == @unchanged.updated_at,
           "Updated date-time should be untouched."
    assert @instance.updated_by != "fred", "Updated by should be untouched."
  end
end
