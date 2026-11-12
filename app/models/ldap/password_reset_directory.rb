# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# The Active Directory calls behind an administrator's password reset
# (Users::PasswordResetService). Everything is read from AD at the moment it is
# asked, never from the session.
#
# Only accounts in the NSL users OU (ldap_users) can have their password
# reset. The administrator may be in either OU, as at sign-in.
#
# Searches raise if AD reports an error, so a failed query can never read as
# "not a member" or "not found".
class Ldap::PasswordResetDirectory
  class Error < StandardError; end

  # AD refused the new password under its password policy (constraint
  # violation, extended error 0000052D).
  class PolicyError < Error; end

  IN_CHAIN_RULE = "1.2.840.113556.1.4.1941" # LDAP_MATCHING_RULE_IN_CHAIN: nested groups
  ACCOUNT_DISABLED_FLAG = 0x2
  CONSTRAINT_VIOLATION = 19
  ATTRIBUTES = %w[dn sAMAccountName displayName memberOf userAccountControl lockoutTime].freeze

  Account = Data.define(:dn, :username, :display_name, :groups, :disabled, :locked) do
    alias_method :disabled?, :disabled
    alias_method :locked?, :locked
  end

  # Binds as the administrator to check their password, then reads their
  # entry. Like sign-in, looks in the NSL users OU, then among the generic
  # users. Returns an Account, or nil if the password is wrong.
  def authenticate(username, password)
    return nil if username.blank? || password.blank?

    [ Ldap::USERS, Ldap::GENERIC_USERS ].compact_blank.each do |base|
      result = connection.bind_as(
        base: base,
        filter: user_filter(username),
        password: password,
        attributes: ATTRIBUTES,
      )
      return account(result.first) if result
    end
    nil
  end

  # The user's account in the NSL users OU, or nil.
  def find_user(username)
    entry = search(base: Ldap::USERS, filter: user_filter(username), attributes: ATTRIBUTES).first
    entry ? account(entry) : nil
  end

  # Whether the account is in a group with one of these names anywhere in the
  # domain, directly or through nested groups. Groups in every environment's
  # OU count, since every environment shares the one AD.
  def member_of_any?(dn, group_names)
    group_dns(group_names).any? do |group_dn|
      search(
        base: dn,
        scope: Net::LDAP::SearchScope_BaseObject,
        filter: Net::LDAP::Filter.ex("memberOf:#{IN_CHAIN_RULE}", Net::LDAP::Filter.escape(group_dn)),
        attributes: [ "dn" ],
      ).any?
    end
  end

  # Raises PolicyError if AD refuses the password under its policy.
  def reset_password(dn, new_password)
    return if connection.replace_attribute(dn, :unicodePwd, unicode_password(new_password))

    result = connection.get_operation_result
    if result.code == CONSTRAINT_VIOLATION || result.error_message.to_s.include?("0000052D")
      raise PolicyError, "Active Directory refused the password under its password policy"
    end

    raise Error, "Password reset failed: #{result.message}"
  end

  def unlock(dn)
    return if connection.replace_attribute(dn, :lockoutTime, "0")

    raise Error, "Unlock failed: #{connection.get_operation_result.message}"
  end

  private

  def connection
    @connection ||= Ldap.new.admin_connection
  end

  def search(**args)
    entries = connection.search(**args)
    result = connection.get_operation_result
    raise Error, "Active Directory search failed: #{result.message}" if !result.code.zero?

    entries || []
  end

  def group_dns(group_names)
    group_names.flat_map do |name|
      search(
        base: domain_base,
        filter: Net::LDAP::Filter.equals("objectClass", "group") & Net::LDAP::Filter.equals("cn", name),
        attributes: [ "dn" ],
      ).map(&:dn)
    end
  end

  # The domain's root, e.g. dc=cloud,dc=biodiversity,dc=org,dc=au
  def domain_base
    Ldap::USERS.split(",").map(&:strip).select { |part| part.match?(/\Adc=/i) }.join(",")
  end

  # equals, not eq: eq doesn't escape, so "*" would match any account.
  def user_filter(username)
    Net::LDAP::Filter.equals(Ldap::USERID_FIELD, username)
  end

  def account(entry)
    Account.new(
      dn: entry.dn,
      username: first_value(entry, :samaccountname),
      display_name: first_value(entry, :displayname),
      groups: environment_groups(entry[:memberof]),
      disabled: first_value(entry, :useraccountcontrol).to_i.anybits?(ACCOUNT_DISABLED_FLAG),
      locked: first_value(entry, :lockouttime).to_i.positive?,
    )
  end

  def first_value(entry, attribute)
    entry[attribute].first.to_s
  end

  # Group names in this environment's OU, as read at sign-in (Ldap).
  def environment_groups(member_of)
    member_of.select { |dn| dn.match?(/#{Ldap::GROUP_FILTER_REGEX}/i) }
      .map { |dn| dn.split(",").first.split("=").last }
  end

  # AD wants the password in double quotes, encoded as UTF-16LE.
  def unicode_password(password)
    "\"#{password}\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::BINARY)
  end
end
