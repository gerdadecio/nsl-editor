# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0
require "test_helper"
require "minitest/mock"

# The history page's ticket count comes from the year's change history,
# whether or not Jira statuses are retrieved. The Retrieved timestamp shows
# only when they are.
class HistoryActionsTicketCountTest < ActionDispatch::IntegrationTest
  setup do
    @original_jira_status_aware = Rails.configuration.try(:jira_status_aware)
    @expected_count = JiraTicket.keys_for_year(2026).size
  end

  teardown do
    Rails.configuration.jira_status_aware = @original_jira_status_aware
  end

  test "counts the year's tickets without a Retrieved line when not jira status aware" do
    Rails.configuration.jira_status_aware = false
    get_history_for_2026
    assert_response :success
    assert @expected_count.positive?, "2026 change history should have tickets"
    assert_select "body", /Tickets:#{@expected_count}\b/
    assert_select "body", { text: /Retrieved:/, count: 0 }
  end

  test "counts the year's tickets with a Retrieved line when jira status aware" do
    Rails.configuration.jira_status_aware = true
    JiraTicket.stub(:query_keys, nil) do
      JiraTicket.stub(:results, { "NSL-6013" => "Done" }) do
        get_history_for_2026
      end
    end
    assert_response :success
    assert_select "body", /Tickets:#{@expected_count}\b/
    assert_select "body", /Retrieved:/
  end

  private

  def get_history_for_2026
    sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
      get history_for_year_path(year: "2026"), xhr: true
    end
  end
end
