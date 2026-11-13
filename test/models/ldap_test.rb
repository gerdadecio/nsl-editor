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
require "minitest/mock"

# Usernames must be matched exactly in AD lookups (NSL-6053). With an
# unescaped filter, a username like "*" matched existing accounts and the
# password was tried against the first match.
class LdapTest < ActiveSupport::TestCase
  # Stands in for the admin connection: records each lookup and finds nobody,
  # except search, which can be given entries to return.
  class FakeConnection
    attr_reader :bind_as_calls, :search_calls

    def initialize(search_result: [])
      @bind_as_calls = []
      @search_calls = []
      @search_result = search_result
    end

    def bind_as(args)
      @bind_as_calls << args
      false
    end

    def search(args)
      @search_calls << args
      @search_result
    end

    def replace_attribute(*)
      true
    end
  end

  def filter_for(value)
    "(#{Ldap::USERID_FIELD}=#{value})"
  end

  def sign_in_with(username)
    connection = FakeConnection.new
    ldap = Ldap.new(username: username, password: "a password")
    ldap.stub(:admin_connection, connection) do
      assert_not ldap.valid?
    end
    connection
  end

  test "a wildcard username is matched literally, not against every account" do
    connection = sign_in_with("*")

    assert_equal 2, connection.bind_as_calls.size
    connection.bind_as_calls.each do |call|
      assert_equal filter_for("\\2A"), call[:filter].to_s
    end
  end

  test "filter special characters in a username are all escaped" do
    connection = sign_in_with("a*b(c)\\")

    connection.bind_as_calls.each do |call|
      assert_equal filter_for("a\\2Ab\\28c\\29\\5C"), call[:filter].to_s
    end
  end

  test "a plain username is looked up as typed, in users then generic users" do
    connection = sign_in_with("fred")

    assert_equal [ Ldap::USERS, Ldap::GENERIC_USERS ], connection.bind_as_calls.pluck(:base)
    connection.bind_as_calls.each do |call|
      assert_equal filter_for("fred"), call[:filter].to_s
    end
  end

  test "change password looks the user up exactly" do
    connection = FakeConnection.new(search_result: [ Struct.new(:dn).new("cn=someone") ])
    ldap = Ldap.new
    ldap.stub(:admin_connection, connection) do
      ldap.change_password("*", "New-password1", "seed")
    end

    assert_equal [ filter_for("\\2A") ], connection.search_calls.map { |call| call[:filter].to_s }
  end
end
