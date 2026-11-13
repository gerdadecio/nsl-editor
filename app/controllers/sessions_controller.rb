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
class SessionsController < ApplicationController
  skip_before_action :authenticate

  # Slow down password guessing (NSL-6052). Three limits on sign-in attempts,
  # each refused before LDAP is asked:
  #
  # - Per client IP: guessing from one client, across any accounts. Behind the
  #   AWS ALB, remote_ip is the client's address (the ALB's private address is
  #   a trusted proxy).
  # - Per username: guessing at one account from many IPs. Keep it below the
  #   AD lockout threshold, so the Editor stops before AD locks the account
  #   (and if AD lockout is off, this is the only per-account cap). Anyone can
  #   block a known username from signing in here for the window, which is
  #   milder than the AD lockout the same guesses would cause.
  # - Global: password spraying, one common password tried once per username
  #   from many IPs, which no per-IP or per-account limit sees. A spray burst
  #   can block all sign-ins for up to the window.
  #
  # Every attempt counts, successful or not. Counts live in Rails.cache, so
  # each app container counts separately: with N containers, each limit is
  # effectively N times higher.
  PER_IP_LIMIT = 10
  PER_IP_WINDOW = 3.minutes
  PER_USERNAME_LIMIT = 5
  PER_USERNAME_WINDOW = 15.minutes
  GLOBAL_LIMIT = 100
  GLOBAL_WINDOW = 5.minutes

  rate_limit to: PER_IP_LIMIT, within: PER_IP_WINDOW, only: :create, name: "ip",
    with: -> { too_many_sign_in_attempts(:ip) }
  rate_limit to: PER_USERNAME_LIMIT, within: PER_USERNAME_WINDOW, only: :create, name: "username",
    by: -> { rate_limit_username }, with: -> { too_many_sign_in_attempts(:username) }
  rate_limit to: GLOBAL_LIMIT, within: GLOBAL_WINDOW, only: :create, name: "global",
    by: -> { "all" }, with: -> { too_many_sign_in_attempts(:global) }

  def new
    build_sign_in
  end

  def retry_new
    build_sign_in
    @sign_in.errors[:base] << "Please retry.  There was a system problem."
    render("new")
  end

  # Known problem: if login is rejected due to no login authority
  # entering a legit username/password into the re-rendered sign in form
  # fails the first time.
  def create
    build_sign_in
    if @sign_in.save && authorised_to_login?
      reset_session_keeping_deep_link
      set_up_session
      deep_link || redirect_to(:root)
    else
      render("new", status: :unprocessable_content)
    end
  rescue StandardError => e
    logger.error("Exception signing in: #{e.to_s.gsub(/password:[^,]*/, "password: [filtered]")}")
    redirect_to(:retry_start_sign_in)
  end

  def destroy
    reset_session
    redirect_to(:start_sign_in)
  end

  # For testing.
  def throw_invalid_authenticity_token
    raise ActionController::InvalidAuthenticityToken
  end

  private

  # Runs instead of create once a rate limit is hit, so LDAP is not asked.
  # The message doesn't say which limit was hit; the log does, without the
  # username or IP.
  def too_many_sign_in_attempts(limit)
    logger.warn("Sign-in rate limit hit: #{limit}")
    build_sign_in
    @sign_in.errors.add(:base, "Too many sign-in attempts. Please wait a few minutes and try again.")
    render("new", status: :too_many_requests)
  end

  # The username the per-username limit counts against. AD matches usernames
  # case-insensitively, so "Fred" and " fred " share one count. Runs in a
  # before_action, outside create's rescue, so malformed params must not raise.
  def rate_limit_username
    sign_in = params[:sign_in]
    return "" if !sign_in.is_a?(ActionController::Parameters)

    sign_in[:username].to_s.strip.downcase
  end

  def build_sign_in
    @sign_in = SignIn.new(sign_in_params)
    @no_searchbar = true
    @no_search_result_details = true
    @no_advanced_search = true
    @no_menus = true
  end

  # Start a fresh session on successful sign-in so no session issued before
  # authentication (planted or otherwise) carries over: rules out session
  # fixation whatever the session store. Only the deep link survives. The
  # reset lives here, not in build_sign_in: resetting on every sign-in page
  # load (new, retry_new, failed create) is what broke deep links in 2020
  # (6203bc092).
  def reset_session_keeping_deep_link
    url_after_sign_in = session[:url_after_sign_in]
    reset_session
    session[:url_after_sign_in] = url_after_sign_in if url_after_sign_in.present?
  end

  # The user's LDAP groups (edit, admin, treebuilder, etc.) are read once, here,
  # and kept in the session cookie. ApplicationController#continue_user_session
  # trusts them on every request without asking LDAP again. So a change to
  # someone's LDAP groups, including removing access, only takes effect when
  # they next sign in. The cookie expires after 3 hours *idle*
  # (config/initializers/session_store.rb: expire_after is renewed on every
  # request), so an active user keeps their old groups until they sign out.
  # To cut off access sooner, rotate session_key_tag so every session ends.
  # Database-backed roles (via User) are not affected: they're read per request.
  def set_up_session
    session[:username] = sign_in_params[:username].downcase
    session[:groups] = @sign_in.groups
    session[:user_full_name] = @sign_in.user_full_name
    session[:user_cn] = @sign_in.user_cn
    session[:generic_active_directory_user] = @sign_in.generic_active_directory_user
    session[:include_common_and_cultivar] = false
    session[:workspace] = {}
  end

  # Uses up the deep link, and follows it only if it is a local path.
  def deep_link
    url_after_sign_in = session.delete(:url_after_sign_in)
    return false if !local_path?(url_after_sign_in)

    redirect_to(url_after_sign_in)
  end

  # A path on this app ("/search?..."), not a full URL or a protocol-relative
  # one ("//host", or "/\host", which browsers read the same way). Anything
  # else is dropped and sign-in goes to root.
  def local_path?(url)
    url.is_a?(String) && url.start_with?("/") && !url.start_with?("//", "/\\")
  end

  def sign_in_params
    sign_in_params = params[:sign_in]
    sign_in_params&.permit(:username, :password)
  end

  def authorised_to_login?
    if @sign_in.groups.include?("login")
      true
    else
      @sign_in.make_invalid # simulate failed credentials
      reset_session
      false
    end
  end
end
