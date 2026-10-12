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
# HTTP calls to NSL Services and the Mapper. Use these in place of
# RestClient.get/post/put/delete: they take the same arguments.
#
# Every call gets a short open_timeout. Opening a connection takes well under
# a second, so if it hasn't happened in 10 seconds the service is down, and we
# fail fast rather than hold a Puma thread for Net::HTTP's default 60 seconds.
# The read timeout stays at the 60 second default unless a caller passes one,
# because some tree operations (creating a draft, reports) are legitimately
# slow.
#
# Services URLs carry the API key in the query string. Log them with
# ServicesHttp.loggable(url), never the raw url.
module ServicesHttp
  OPEN_TIMEOUT = 10

  def self.get(url, headers = {}, read_timeout: nil)
    execute(:get, url, nil, headers, read_timeout)
  end

  def self.post(url, payload, headers = {}, read_timeout: nil)
    execute(:post, url, payload, headers, read_timeout)
  end

  def self.put(url, payload, headers = {}, read_timeout: nil)
    execute(:put, url, payload, headers, read_timeout)
  end

  def self.delete(url, headers = {}, read_timeout: nil)
    execute(:delete, url, nil, headers, read_timeout)
  end

  def self.execute(method, url, payload, headers, read_timeout)
    args = { method: method, url: url, headers: headers, open_timeout: OPEN_TIMEOUT }
    args[:payload] = payload unless payload.nil?
    args[:read_timeout] = read_timeout if read_timeout
    RestClient::Request.execute(**args)
  end
  private_class_method :execute

  def self.loggable(url)
    url.to_s.gsub(/(apiKey=)[^&]*/, '\1[FILTERED]')
  end
end
