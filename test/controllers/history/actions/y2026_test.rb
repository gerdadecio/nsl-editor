# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
require "minitest/mock"
require "tmpdir"

# The 2026 page shows pending entries above the yearly file's entries.
class HistoryActionsY2026Test < ActionDispatch::IntegrationTest
  test "history 2026 page shows pending and yearly entries" do
    Dir.mktmpdir do |dir|
      FileUtils.cp("config/history/changes-2026.yml", dir)
      FileUtils.mkdir_p(File.join(dir, "pending"))
      # Count from the copy, so real pending files don't change the total.
      yearly_count = ChangeHistory.stub(:default_dir, dir) { JiraTicket.keys_for_year(2026).size }
      File.write(File.join(dir, "pending", "NSL-9999.yml"), <<~YAML)
        - :date: 31-December-2026
          :jira_id: '9999'
          :description: |-
            Testing: A pending change
      YAML

      ChangeHistory.stub(:default_dir, dir) do
        sign_in_as_fake_user(username: "fred", full_name: "Fred Jones", groups: []) do
          get history_for_year_path(year: "2026"), xhr: true
        end
      end

      assert_response :success
      assert_select "h3", /\bChanges 2026\b/
      assert_select "body", /NSL-9999.*Testing: A pending change/m
      assert_select "body", /NSL-6039/
      assert_select "body", /Tickets:#{yearly_count + 1}\b/
      assert response.body.index("NSL-9999") < response.body.index("NSL-6039"), "the pending entry should be listed first"
    end
  end
end
