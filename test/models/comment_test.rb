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
require "test_helper"

# Comment tests.
class CommentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  #
  # insert comment attached to instance
  # insert comment attached to reference
  # insert comment attached to name
  # insert comment attached to author
  # insert comment with 2 parents - should fail
  #

  test "author comment fixture should be valid" do
    author_comment = comments("author_comment")
    assert author_comment.present?
    assert author_comment.valid?, "Comment fixture author_comment shld be valid"
  end

  test "instance comment fixture should be valid" do
    instance_comment = comments("instance_comment")
    assert instance_comment.present?
    assert instance_comment.valid?, "Instance comment fixture should be valid"
  end

  test "name comment fixture should be valid" do
    name_comment = comments("name_comment")
    assert name_comment.present?
    assert name_comment.valid?, "Name comment fixture should be valid"
  end

  test "reference comment fixture should be valid" do
    reference_comment = comments("reference_comment")
    assert reference_comment.present?
    assert reference_comment.valid?, "Reference comment fixture should be valid"
  end

  test "comment with no parent" do
    author_comment = comments("author_comment")
    assert author_comment.present?
    author_comment.author_id = nil
    assert_not author_comment.valid?, "comment with no parent should be valid"
  end

  test "author comment with instance parent" do
    author_comment = comments("author_comment")
    assert author_comment.present?
    author_comment.instance = instances("triodia_in_brassard")
    assert_not author_comment.valid?,
               "Comment with 2 parents (author and instance) should be invalid"
  end

  test "author comment with name parent" do
    author_comment = comments("author_comment")
    assert author_comment.present?
    author_comment.name = names("a_species")
    assert_not author_comment.valid?,
               "Comment with 2 parents (author and name) should be invalid"
  end

  test "author comment with reference parent" do
    author_comment = comments("author_comment")
    assert author_comment.present?
    author_comment.reference =
      references("handbook_of_the_vascular_plants_of_sydney")
    assert_not author_comment.valid?,
               "Comment with 2 parents (author and reference) should be invalid"
  end

  test "create comment with no text" do
    comment = Comment.new
    comment.name = names("a_species")
    assert_not comment.valid?, "Comment without text should be invalid"
  end

  test "update comment to have no text" do
    author_comment = comments("author_comment")
    author_comment.text = nil
    assert_not author_comment.valid?, "Comment without text should be invalid"
  end
end
