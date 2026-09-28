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

# A soft deleted name must never be offered by a name typeahead. Each case
# first checks the name is offered while live, so the exclusion is what
# removes it.
class NameTypeaheadsExcludeSoftDeletedTest < ActiveSupport::TestCase
  setup do
    @name = names(:angophora_costata)
  end

  test "parent suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead::ForParent.new(term: "angophora costata", avoid_id: -1,
                                       rank_id: name_ranks(:unranked).id)
                                  .suggestions
    end
  end

  test "cultivar parent suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead.cultivar_parent_suggestions("angophora costata", -1)
    end
  end

  test "hybrid parent suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead.hybrid_parent_suggestions("angophora costata", -1)
    end
  end

  test "duplicate suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead.duplicate_suggestions("angophora costata", -1)
    end
  end

  test "full name suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead::OnFullName.new(term: "angophora costata").suggestions
    end
  end

  test "unpublished citation suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead::ForUnpubCit.new(term: "angophora costata").suggestions
    end
  end

  test "intended tree parent suggestions exclude soft deleted names" do
    assert_excluded_once_soft_deleted do
      Loader::Name::Match::AsTypeahead::ForIntendedTreeParentInstance
        .new(term: "angophora costata").suggestions
    end
  end

  test "family suggestions exclude soft deleted names" do
    @name = names(:a_family)
    assert_excluded_once_soft_deleted do
      Name::AsTypeahead::ForFamily.new(term: "a_family").suggestions
    end
  end

  private

  def assert_excluded_once_soft_deleted
    assert_includes yield.pluck(:id), @name.id, "Live name should be offered."
    @name.update_column(:deleted_at, Time.current)
    assert_not_includes yield.pluck(:id), @name.id
  end
end
