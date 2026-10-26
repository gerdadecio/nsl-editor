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

# Mapper calls use a short read timeout. RestClient timeouts are
# ExceptionWithResponse subclasses with no response, so the rescue blocks must
# not call e.response.code on them.
class TreeAsServicesMapperTimeoutTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:code, :body) do
    def to_s = body.to_s
  end

  def raising(error)
    ->(**_args) { raise error }
  end

  test "mapper lookups use the short mapper read timeout" do
    args = nil
    response = FakeResponse.new(200, '{"link":"https://id.example/instance/1"}')
    RestClient::Request.stub(:execute, ->(**a) { args = a; response }) do
      assert_equal "https://id.example/instance/1", Tree::AsServices.instance_url(1)
    end

    assert_equal Tree::AsServices::MAPPER_READ_TIMEOUT, args[:read_timeout]
    assert_equal ServicesHttp::OPEN_TIMEOUT, args[:open_timeout]
  end

  test "a timed out instance lookup raises the timeout" do
    RestClient::Request.stub(:execute, raising(RestClient::Exceptions::ReadTimeout.new)) do
      assert_raises(RestClient::Exceptions::ReadTimeout) { Tree::AsServices.instance_url(1) }
    end
  end

  test "an instance lookup that fails to open a connection raises the timeout" do
    RestClient::Request.stub(:execute, raising(RestClient::Exceptions::OpenTimeout.new)) do
      assert_raises(RestClient::Exceptions::OpenTimeout) { Tree::AsServices.instance_url(1) }
    end
  end

  test "a 404 instance lookup adds the instance link" do
    not_found = RestClient::NotFound.new(FakeResponse.new(404, "not found"))
    RestClient::Request.stub(:execute, raising(not_found)) do
      Tree::AsServices.stub(:add_instance_link, ->(id) { "https://id.example/instance/#{id}" }) do
        assert_equal "https://id.example/instance/1", Tree::AsServices.instance_url(1)
      end
    end
  end

  test "other instance lookup errors still return nil" do
    server_error = RestClient::InternalServerError.new(FakeResponse.new(500, "oops"))
    RestClient::Request.stub(:execute, raising(server_error)) do
      assert_nil Tree::AsServices.instance_url(1)
    end
  end

  test "a timed out v1 add instance link raises the timeout" do
    RestClient::Request.stub(:execute, raising(RestClient::Exceptions::ReadTimeout.new)) do
      assert_raises(RestClient::Exceptions::ReadTimeout) { Tree::AsServices.add_instance_link_v1(1) }
    end
  end

  test "a timed out v2 add instance link raises the timeout" do
    jwt = OpenStruct.new(access_token: "token")
    Tree::AsServices.stub(:mapper_auth, jwt) do
      RestClient::Request.stub(:execute, raising(RestClient::Exceptions::ReadTimeout.new)) do
        assert_raises(RestClient::Exceptions::ReadTimeout) { Tree::AsServices.add_instance_link_v2(1) }
      end
    end
  end
end
