# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# NSL-6047: a password administrator resets another NSL user's Active
# Directory password, and unlocks the account if it is locked out.
#
# Every check is made in AD at the time of the reset, not from the session:
# the administrator re-enters their password, and that bind reads their
# current groups, so someone taken out of password-admin loses the power
# straight away.
#
# Refused:
# - when the feature is off (password_reset_enabled). All environments share
#   one AD, so only production should turn it on
# - the administrator gets their password wrong, or isn't in password-admin
#   in this environment's OU. They may be an NSL or a generic AD user
# - the administrator's own account: they use the Change Password page
# - the account isn't in the NSL users OU, or is disabled
# - the account is in the password reset group (another password
#   administrator) in any environment's OU, directly or through nested groups
#
# The temporary password is returned to the caller to show once. It is never
# stored or logged. Every attempt is logged with one PASSWORD_RESET line.
class Users::PasswordResetService < BaseService
  # A group nobody is in: until password_reset_group is set, no one can reset
  # passwords. The real group name stays in the config file.
  DEFAULT_GROUP = "unknown-group"
  POLICY_ATTEMPTS = 3
  SELF_MESSAGE = "Use Change Password to change your own password."

  class Refused < StandardError
    attr_reader :reason

    def initialize(reason, message)
      @reason = reason
      super(message)
    end
  end

  attr_reader :temporary_password, :reason, :unlocked, :unlock_failed

  def initialize(user:, admin_username:, admin_password:, ip:,
    directory: Ldap::PasswordResetDirectory.new)
    super({})
    @user = user
    @admin_username = admin_username.to_s.downcase
    @admin_password = admin_password
    @ip = ip
    @directory = directory
  end

  # What the Password tab shows before anyone asks for a reset: why the
  # account can't be reset, if it can't, and whether it is locked out.
  # Advisory only: the reset makes every check again.
  TargetCheck = Data.define(:reason, :message, :locked) do
    def resettable?
      reason.nil? || reason == "unavailable"
    end
  end

  def self.enabled?
    Rails.configuration.try(:password_reset_enabled) == true
  end

  # The AD group whose members can reset passwords: password_reset_group in
  # the config file, or DEFAULT_GROUP if that's not set.
  def self.group
    Rails.configuration.try(:password_reset_group).presence || DEFAULT_GROUP
  end

  # Accounts in these groups can't have their password reset here. Admins are
  # not protected, by request: a password administrator may reset an admin's
  # password.
  def self.protected_groups
    [ group ]
  end

  def self.check_target(user, admin_username:, directory: Ldap::PasswordResetDirectory.new)
    username = user.user_name.to_s.downcase
    return TargetCheck.new(reason: "self", message: SELF_MESSAGE, locked: false) if username == admin_username.to_s.downcase

    target = directory.find_user(username)
    reason, message = target_refusal(username, target, directory)
    TargetCheck.new(reason: reason, message: message, locked: target&.locked? || false)
  rescue StandardError => e
    Rails.logger.error("Users::PasswordResetService.check_target: #{e.class}: #{e.message}")
    TargetCheck.new(reason: "unavailable", locked: false,
      message: "Active Directory couldn't be reached to check this account. You can still try the reset.")
  end

  # [reason, message] if the account can't have its password reset, else nil.
  def self.target_refusal(username, target, directory)
    if target.nil?
      [ "not-found", "#{username} isn't an NSL account in Active Directory (it may be a generic account), so its password can't be reset here." ]
    elsif target.disabled?
      [ "disabled", "The account #{username} is disabled in Active Directory, so its password can't be reset here." ]
    elsif directory.member_of_any?(target.dn, protected_groups)
      [ "protected-group", "The account #{username} is a password administrator, so its password can't be reset here." ]
    end
  end

  def execute
    check_allowed
    @target = find_target
    reset_password
    unlock_if_locked
    log_attempt("success")
  rescue Refused => e
    refuse(e.reason, e.message)
  rescue Ldap::PasswordResetDirectory::PolicyError
    refuse("policy", "Active Directory refused the new password under its password policy. Nothing was changed. Please try again.")
  rescue StandardError => e
    @logger.error("Users::PasswordResetService: #{e.class}: #{e.message}")
    refuse("error", "Active Directory reported a problem, so the password was not changed. Please try again later.")
  end

  def success?
    errors.empty? && temporary_password.present?
  end

  def target_username
    @user.user_name.to_s.downcase
  end

  private

  def check_allowed
    raise Refused.new("feature-off", "Password reset is not turned on for this Editor.") if !self.class.enabled?
    raise Refused.new("self", SELF_MESSAGE) if target_username == @admin_username
    raise Refused.new("no-admin-password", "Please enter your own password.") if @admin_password.blank?

    admin = @directory.authenticate(@admin_username, @admin_password)
    raise Refused.new("bad-admin-password", "Your password was not accepted.") if admin.nil?
    raise Refused.new("not-password-admin", "You are not in the #{self.class.group} group.") if !admin.groups.include?(self.class.group)
  end

  def find_target
    target = @directory.find_user(target_username)
    refusal = self.class.target_refusal(target_username, target, @directory)
    raise Refused.new(*refusal) if refusal

    target
  end

  # A new password each time AD refuses one under its policy, e.g. one that
  # turns out to contain part of the user's name.
  def reset_password
    attempts = 0
    begin
      attempts += 1
      password = TemporaryPassword.generate(avoid: [ @target.username, @target.display_name ])
      @directory.reset_password(@target.dn, password)
      @temporary_password = password
    rescue Ldap::PasswordResetDirectory::PolicyError
      retry if attempts < POLICY_ATTEMPTS
      raise
    end
  end

  # The password is already reset by now, so a failed unlock is reported, not
  # treated as a failed reset.
  def unlock_if_locked
    return if !@target.locked?

    @directory.unlock(@target.dn)
    @unlocked = true
  rescue StandardError => e
    @logger.error("Users::PasswordResetService unlock: #{e.class}: #{e.message}")
    @unlock_failed = true
  end

  def refuse(reason, message)
    @reason = reason
    @temporary_password = nil
    errors.add(:base, message)
    log_attempt(reason == "error" ? "failed" : "refused")
  end

  def log_attempt(result)
    @logger.info(
      "PASSWORD_RESET admin=#{@admin_username} target=#{target_username} " \
      "result=#{result} reason=#{@reason || "-"} unlocked=#{@unlocked ? "yes" : "no"}" \
      "#{" unlock=failed" if @unlock_failed} ip=#{@ip}",
    )
  end
end
