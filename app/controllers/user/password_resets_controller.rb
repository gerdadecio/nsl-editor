# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# NSL-6047: Password tab on a user record. A password administrator resets the
# user's AD password; Users::PasswordResetService makes the checks.
#
# The temporary password is rendered straight into this POST's response and
# nowhere else: no flash, no redirect, no session (the session is a cookie),
# and the response is marked no-store.
class User::PasswordResetsController < ApplicationController
  # Each attempt binds as the administrator to check their password, and too
  # many wrong passwords would lock them out of AD. Stop well before that.
  # Counted per administrator, in Rails.cache.
  rate_limit to: 5, within: 15.minutes, only: :create,
    by: -> { session[:username] }, with: :too_many_attempts

  before_action :no_store
  before_action :find_user

  # POST /users/:id/password_reset
  def create
    @reset = Users::PasswordResetService.call(
      user: @user,
      admin_username: current_user.username,
      admin_password: params.dig(:password_reset, :admin_password),
      ip: request.remote_ip,
    )
    render("create", status: @reset.success? ? :ok : :unprocessable_content)
  end

  private

  def no_store
    response.headers["Cache-Control"] = "no-store"
  end

  def find_user
    @user = User.find(params[:id])
  end

  def too_many_attempts
    @message = "Too many password reset attempts. Please wait a few minutes and try again."
    render("too_many_attempts", status: :too_many_requests)
  end
end
