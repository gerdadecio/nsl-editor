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
class SignIn < ActiveType::Object
  NOT_VERIFIED = "not verified."

  attribute :username, :string
  attribute :password, :string

  validates :username, presence: true
  validates :password, presence: true

  validate :validate_credentials

  def groups
    @ldap.users_groups
  end

  delegate :user_full_name, to: :@ldap

  delegate :user_cn, to: :@ldap

  delegate :generic_active_directory_user, to: :@ldap

  # The account's password was right but it may not sign in to the Editor
  # (no login group). Shows the same message as a wrong password, so the page
  # can't be used to check whether a password is valid for an AD account
  # (NSL-6059). The log says which it was, without the username.
  def make_invalid
    Rails.logger.info("Sign-in refused: credentials verified but no login group")
    errors.add(:credentials, NOT_VERIFIED)
  end

  private

  def validate_credentials
    return if build_ldap.save

    Rails.logger.info("Sign-in refused: credentials not verified")
    errors.add(:credentials, NOT_VERIFIED)
  end

  def build_ldap
    credentials = {}
    credentials[:username] = username
    credentials[:password] = password
    @ldap = Ldap.new(credentials)
  end
end
