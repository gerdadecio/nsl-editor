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
class FixtureBTest < ActiveSupport::TestCase
  test "fixture a_superordo name should be valid" do
    name = names(:a_superordo)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_superordo name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture an_ordo name should be valid" do
    name = names(:an_ordo)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture an_ordo name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_family name should be valid" do
    name = names(:a_family)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_family name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subfamilia name should be valid" do
    name = names(:a_subfamilia)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subfamilia name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_tribus name should be valid" do
    name = names(:a_tribus)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_tribus name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subtribus name should be valid" do
    name = names(:a_subtribus)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subtribus name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a genus name should be valid" do
    name = names(:a_genus)
    assert name.valid?, "Fixture a_genus name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subgenus name should be valid" do
    name = names(:a_subgenus)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subgenus name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_sectio name should be valid" do
    name = names(:a_sectio)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_sectio name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subsectio name should be valid" do
    name = names(:a_subsectio)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subsectio name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_series name should be valid" do
    name = names(:a_series)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_series name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_subseries name should be valid" do
    name = names(:a_subseries)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_subseries name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_superspecies name should be valid" do
    name = names(:a_superspecies)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_superspecies name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end

  test "fixture a_species name should be valid" do
    name = names(:a_species)
    assert name.present?, "No such name"
    assert name.valid?, "Fixture a_species name should be valid.
                         Errors: #{name.errors.full_messages.join("; ")}"
  end
end
