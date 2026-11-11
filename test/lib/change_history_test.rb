# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"
require "tmpdir"

class ChangeHistoryTest < ActiveSupport::TestCase
  YEARLY = <<~YAML
    - :date: 09-November-2026
      :jira_id: '6039'
      :description: |-
        Loader: Order preferred matches
    - :date: 06-November-2026
      :jira_id: '6040'
      :description: |-
        Security: Upgrade Rails
    - :date: 21-October-2026
      :release: true
      :release_version: 5.1.5.33
    - :date: 21-August-2026
      :jira_id: '3732'
      :description: |-
        Soft delete: Fix
  YAML

  setup do
    @dir = Dir.mktmpdir
    FileUtils.mkdir_p(File.join(@dir, "pending"))
    File.write(File.join(@dir, "changes-2026.yml"), YEARLY)
  end

  teardown do
    FileUtils.remove_entry(@dir)
  end

  test "changes lists pending entries newest first, then the yearly file in its own order" do
    add_pending("NSL-6042", "12-November-2026", "6042")
    add_pending("NSL-6050", "15-November-2026", "6050")
    add_pending("NSL-6043", "12-November-2026", "6043")

    ids = ChangeHistory.changes(2026, dir: @dir).map { |entry| entry[:jira_id] || entry[:release_version] }

    assert_equal %w[6050 6043 6042 6039 6040 5.1.5.33 3732], ids
  end

  test "changes leaves out pending entries from other years" do
    add_pending("NSL-7001", "05-January-2027", "7001")

    assert_equal %w[6039 6040], ChangeHistory.changes(2026, dir: @dir).first(2).map { |entry| entry[:jira_id] }
    assert_equal %w[7001], ChangeHistory.changes(2027, dir: @dir).map { |entry| entry[:jira_id] }
  end

  test "changes works with no pending folder and no yearly file" do
    FileUtils.rm_rf(File.join(@dir, "pending"))

    assert_equal 4, ChangeHistory.changes(2026, dir: @dir).size
    assert_equal [], ChangeHistory.changes(2030, dir: @dir)
  end

  test "changes skips a pending file with a bad date or bad YAML, and the strict reader reports it" do
    add_pending("NSL-6042", "sometime soon", "6042")
    File.write(File.join(@dir, "pending", "NSL-6044.yml"), "- :date: [unclosed\n")

    assert_equal 4, ChangeHistory.changes(2026, dir: @dir).size
    error = assert_raises(ChangeHistory::Error) { ChangeHistory.pending_files(dir: @dir) }
    assert_match(/NSL-6042\.yml.*:date:/, error.message)
  end

  test "fold! moves pending entries to the top newest first, without touching the rest" do
    add_pending("NSL-6042", "12-November-2026", "6042")
    add_pending("NSL-6050", "15-November-2026", "6050")
    add_pending("NSL-7001", "05-January-2027", "7001")

    assert_equal 3, ChangeHistory.fold!(dir: @dir)

    text = File.read(File.join(@dir, "changes-2026.yml"))
    assert text.end_with?(YEARLY), "the existing entries should be unchanged"
    assert_equal %w[6050 6042 6039], YAML.load(text).first(3).map { |entry| entry[:jira_id] }
    assert_equal %w[7001], YAML.load_file(File.join(@dir, "changes-2027.yml")).map { |entry| entry[:jira_id] }
    assert_empty Dir.glob(File.join(@dir, "pending", "*.yml"))
    assert_equal 0, ChangeHistory.fold!(dir: @dir), "a second run has nothing to do"
  end

  test "fold! changes nothing when a pending file is malformed" do
    add_pending("NSL-6042", "12-November-2026", "6042")
    add_pending("NSL-6043", "not a date", "6043")

    assert_raises(ChangeHistory::Error) { ChangeHistory.fold!(dir: @dir) }
    assert_equal YEARLY, File.read(File.join(@dir, "changes-2026.yml"))
    assert_equal 2, Dir.glob(File.join(@dir, "pending", "*.yml")).size
  end

  test "insert_release_marker goes above the newest released entry" do
    released = YAML.load(YEARLY).drop(1) # released before 6039 merged

    text = ChangeHistory.insert_release_marker(YEARLY, released, version: "5.1.6.0", date: "10-November-2026")

    entries = YAML.load(text)
    assert_equal "6039", entries[0][:jira_id]
    assert_equal({ date: "10-November-2026", release: true, release_version: "5.1.6.0" }, entries[1])
    assert_equal "6040", entries[2][:jira_id]
  end

  test "insert_release_marker goes at the bottom when none of the year's entries were released" do
    text = ChangeHistory.insert_release_marker(YEARLY, [], version: "5.1.6.0", date: "10-November-2026")

    assert_equal "5.1.6.0", YAML.load(text).last[:release_version]
  end

  test "insert_release_marker refuses a repeat release or released entries it can't find" do
    assert_raises(ChangeHistory::Error) do
      ChangeHistory.insert_release_marker(YEARLY, [], version: "5.1.5.33", date: "10-November-2026")
    end
    missing = [ { date: "01-May-2026", jira_id: "1", description: "Not in the file" } ]
    assert_raises(ChangeHistory::Error) do
      ChangeHistory.insert_release_marker(YEARLY, missing, version: "5.1.6.0", date: "10-November-2026")
    end
  end

  test "the repo's pending changelog files are valid" do
    files = assert_nothing_raised { ChangeHistory.pending_files }
    files.each do |file|
      assert_includes file.text.lines.first, "- :date:", "#{file.path} should start with '- :date:'"
    end
  end

  private

  def add_pending(name, date, jira_id)
    File.write(File.join(@dir, "pending", "#{name}.yml"), <<~YAML)
      - :date: #{date}
        :jira_id: '#{jira_id}'
        :description: |-
          Change #{jira_id}
    YAML
  end
end
