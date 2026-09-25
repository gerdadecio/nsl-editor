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

# Name fixture tests.
class FixtureCTest < ActiveSupport::TestCase
  test "fixture a_subspecies name should be valid" do
    name = names(:a_subspecies)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subspecies name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_nothovarietas name should be valid" do
    name = names(:a_nothovarietas)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_nothovarietas name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_varietas name should be valid" do
    name = names(:a_varietas)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_varietas name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subvarietas name should be valid" do
    name = names(:a_subvarietas)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subvarietas name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_forma name should be valid" do
    name = names(:a_forma)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_forma name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subforma name should be valid" do
    name = names(:a_subforma)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subforma name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture scientific name without author should be valid" do
    name = names(:scientific_name_without_author)
    assert name.valid?, "Fixture scientific name without author should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end
end
