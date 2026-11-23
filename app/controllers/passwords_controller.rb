# frozen_string_literal: true

#   Copyright 2019 Australian National Botanic Gardens
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
# Administrator Actions
class PasswordsController < ApplicationController
  before_action :hide_details, :empty_search
  # Generic Active Directory users can't change their password, so block
  # every step of the flow, including going straight to the form URL.
  before_action :reject_generic_user, only: %i[edit update show_password_form]

  # Each update binds to AD with the submitted current password, so without
  # a limit anyone holding a session could guess it endlessly, and AD's
  # lockout would lock the real owner out (NSL-6060). Counted per signed-in
  # user, like sign-in's per-username limit, and kept below the AD lockout
  # threshold for the same reason. Counts live in Rails.cache (per app
  # container) and are separate from sign-in's counts.
  PER_USER_LIMIT = 5
  PER_USER_WINDOW = 15.minutes

  rate_limit to: PER_USER_LIMIT, within: PER_USER_WINDOW, only: :update, name: "password-username",
    by: -> { session[:username].to_s.strip.downcase }, with: -> { too_many_password_attempts }

  def edit
    edit_inner
  rescue StandardError => e
    logger.error("Password change error: #{e}")
    render(:edit_error)
  end

  def update
    update_inner
  end

  def show_password_form
    @password = Password.new
  end

  private

  # Runs instead of update once the limit is hit, so AD is not asked.
  # The log doesn't name the user.
  def too_many_password_attempts
    logger.warn("Password change rate limit hit")
    @password = Password.new
    @password.error = "Too many password change attempts. Please wait a few minutes and try again."
    render(:show_password_form, status: :too_many_requests)
  end

  def reject_generic_user
    render(:edit_error) if session[:generic_active_directory_user]
  end

  def edit_inner
    @password = Password.new
    redirect_to(action: :show_password_form)
  end

  def update_inner
    @password = Password.new
    @password.current_password = params[:password]["current_password"]
    @password.new_password = params[:password]["new_password"]
    @password.new_password_confirmation = params[:password]["new_password_confirmation"]
    @password.username = @current_user.username
    @password.user_cn = session[:user_cn]
    if @password.save!
      redirect_to(:password_changed)
    else
      render(:show_password_form, status: :unprocessable_content)
    end
  rescue StandardError => e
    Rails.logger.error(e.to_s)
    render(:show_password_form, status: :unprocessable_content)
  end
end
