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

require "minitest/mock"

# Signs a user in for an ActionDispatch::IntegrationTest by posting to the
# real sign-in action. Only the LDAP check is faked: SignIn.new answers a
# stand-in that accepts the credentials and reports the given groups, so
# SessionsController#set_up_session fills the session just as it does in
# production. The "login" group is always added, since
# SessionsController#authorised_to_login? rejects users without it.
module IntegrationSignInHelper
  FakeSignIn = Struct.new(:groups, :user_full_name, :user_cn,
                          :generic_active_directory_user,
                          keyword_init: true) do
    def save
      true
    end

    def make_invalid; end
  end

  def sign_in_with(username: "fred", full_name: "Fred Jones", groups: ["edit"])
    fake = FakeSignIn.new(groups: (groups + ["login"]).uniq,
                          user_full_name: full_name,
                          user_cn: full_name,
                          generic_active_directory_user: false)
    SignIn.stub(:new, fake) do
      post sign_in_path,
           params: { sign_in: { username: username, password: "password" } }
    end
    assert_response :redirect
  end
end

class ActionDispatch::IntegrationTest
  include IntegrationSignInHelper
end
