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

# Single Name model test.
class NameElementIsCleanedUpBeforeValidation < ActiveSupport::TestCase
  test "name element with leading trailing spaces cleaned before validation" do
    name = Name.first
    name.name_element = "  has spaces   "
    assert name.valid?,
           "Name.name_element with leading trailing spaces shld be cleaned up."
    name.save
    name_saved = Name.find(name.id)
    assert name_saved.name_element.size == 10,
           "Name.name_element with leading trailing spaces should lose spaces."
  end
end
