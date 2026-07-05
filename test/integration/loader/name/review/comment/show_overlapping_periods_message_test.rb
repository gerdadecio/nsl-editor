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

# Single search controller test.
#
# Note: 
#   xhr: true
#
# stopped this error in test: 
#
# ActionController::InvalidCrossOriginRequest: Security warning: 
#   an embedded <script> tag on another site requested protected JavaScript.
class LoaderNameReviewCommentShowTab < ActionController::TestCase
  tests Loader::NamesController


  # Started GET 
  # "/nsl/editor/loader_names/52428461/tab/tab_comment/accepted
  # ?format=js&tabIndex=undefined&take_focus=true" 
  #
  #  def reviewer_id(username)
  #    reviewers.find_by(user_id: User.find_by_user_name(username)).id
  #  end


  test "show overlapping periods message on comment tab" do
    reviewer = users(:reviewer_one)
    loader_name = loader_names(:accepted_three)
    get('tab',
        params: {id: "#{loader_name.id}", tab: 'tab_comment'},
        format: :js,
        xhr: true,
        session: { username: reviewer.user_name,
                   user_full_name: reviewer.full_name,
                   groups: ["login", "taxonomic-review"]}
       )
    assert_match 'There is more than one active review period for the batch.',
      response.body, "Overlapping review periods should be reported"
  end
end
