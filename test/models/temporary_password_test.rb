# frozen_string_literal: true

#   Copyright 2026 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"

# NSL-6047: temporary passwords for an administrator's password reset.
class TemporaryPasswordTest < ActiveSupport::TestCase
  test "is two capitalised words and two digits" do
    50.times do
      assert_match(/\A[A-Z][a-z]+[A-Z][a-z]+\d\d\z/, TemporaryPassword.generate)
    end
  end

  test "is long enough and meets AD's complexity rule" do
    50.times do
      password = TemporaryPassword.generate
      assert_operator password.length, :>=, TemporaryPassword::MIN_LENGTH
      assert_match(/[A-Z]/, password)
      assert_match(/[a-z]/, password)
      assert_match(/\d/, password)
    end
  end

  test "never contains the account name or a part of the display name" do
    avoid = [ "maple", "Otter Smith" ]
    200.times do
      password = TemporaryPassword.generate(avoid: avoid).downcase
      assert_not_includes password, "maple"
      assert_not_includes password, "otter"
      assert_not_includes password, "smith"
    end
  end

  test "parts of a name shorter than three characters are allowed" do
    assert_match(/\A[A-Z]/, TemporaryPassword.generate(avoid: [ "Jo Li" ]))
  end

  test "the word list is plain lower-case words with no repeats" do
    words = TemporaryPassword::WORDS
    assert_operator words.size, :>=, 500
    assert_equal words.size, words.uniq.size
    words.each { |word| assert_match(/\A[a-z]+\z/, word) }
  end
end
