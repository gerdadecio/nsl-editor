# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# Stands in for Ldap::PasswordResetDirectory, so password reset tests never
# reach Active Directory. Records the resets and unlocks it's asked for.
class FakePasswordResetDirectory
  Account = Ldap::PasswordResetDirectory::Account

  attr_reader :resets, :unlocks
  attr_accessor :admin, :target, :protected, :policy_failures, :fail_unlock, :fail_search

  def initialize(admin_groups: [ "login", "password-admin" ], target_disabled: false, target_locked: false)
    @admin = Account.new(dn: "cn=Anna,ou=users,ou=nsl", username: "anna", display_name: "Anna Admin",
      groups: admin_groups, disabled: false, locked: false)
    @target = Account.new(dn: "cn=User One,ou=users,ou=nsl", username: "uone", display_name: "User One",
      groups: [ "login" ], disabled: target_disabled, locked: target_locked)
    @admin_password = "right-password"
    @protected = false
    @policy_failures = 0
    @resets = []
    @unlocks = []
  end

  def authenticate(username, password)
    admin if username == "anna" && password == @admin_password
  end

  def find_user(username)
    raise Ldap::PasswordResetDirectory::Error, "search failed" if fail_search

    target if username == target.username
  end

  def member_of_any?(_dn, _group_names)
    protected
  end

  def reset_password(dn, password)
    if policy_failures.positive?
      self.policy_failures -= 1
      raise Ldap::PasswordResetDirectory::PolicyError, "policy"
    end
    resets << [ dn, password ]
  end

  def unlock(dn)
    raise Ldap::PasswordResetDirectory::Error, "unlock failed" if fail_unlock

    unlocks << dn
  end
end
