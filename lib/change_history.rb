# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "date"
require "yaml"

# Reads and maintains the change history shown on the History page.
#
# A PR adds its entry as config/history/pending/NSL-<id>.yml, so PRs never edit
# the same file. After the PR merges, bin/fold-history (run by the
# fold-history-and-bump-version workflow) moves the entry to the top of
# config/history/changes-<year>.yml and deletes the pending file.
#
# Plain Ruby (stdlib only), so the bin scripts can use it without Rails.
module ChangeHistory
  # Raised when a pending file or a release marker can't be handled safely.
  class Error < StandardError; end

  # A pending file: where it is, its raw text, and the entries it holds.
  PendingFile = Data.define(:path, :text, :entries)

  DATE_FORMAT = /\A\d{1,2}-[A-Za-z]+-\d{4}\z/

  module_function

  def default_dir
    "config/history"
  end

  def yearly_path(year, dir: default_dir)
    File.join(dir, "changes-#{year}.yml")
  end

  def pending_dir(dir: default_dir)
    File.join(dir, "pending")
  end

  # The year's entries for the History page: pending entries first, newest
  # first, then the yearly file in its own order. Pending files that can't be
  # read are left out, so one bad file can't break the page (a test catches
  # them before merge).
  def changes(year, dir: default_dir)
    pending = pending_files(dir: dir, strict: false).flat_map(&:entries)
    sort_newest_first(pending.select { |entry| entry_year(entry) == year.to_i }) +
      yearly_entries(year, dir: dir)
  end

  def yearly_entries(year, dir: default_dir)
    path = yearly_path(year, dir: dir)
    return [] if !File.exist?(path)

    entries = YAML.load(File.read(path))
    entries.is_a?(Array) ? entries : []
  end

  # Pending files in name order. With strict: true a malformed file raises
  # Error; otherwise it is skipped.
  def pending_files(dir: default_dir, strict: true)
    Dir.glob(File.join(pending_dir(dir: dir), "*.yml")).sort.filter_map do |path|
      read_pending(path, File.read(path))
    rescue Error, Psych::Exception => e
      raise Error, "#{path}: #{e.message}" if strict

      nil
    end
  end

  def read_pending(path, text)
    entries = YAML.load(text)
    if !entries.is_a?(Array) || entries.empty? || !entries.all?(Hash)
      raise Error, "should hold a list entry starting with '- :date:'"
    end

    entries.each do |entry|
      raise Error, ":date: should look like 12-November-2026, not #{entry[:date].inspect}" if entry_date(entry).nil?
    end
    raise Error, "all entries in one file should be in the same year" if entries.map { |e| entry_year(e) }.uniq.size > 1

    PendingFile.new(path: path, text: text, entries: entries)
  end

  # The entry's :date: as a Date, or nil if it isn't in DD-Month-YYYY form.
  def entry_date(entry)
    value = entry[:date].to_s.strip
    return nil if !value.match?(DATE_FORMAT)

    Date.parse(value)
  rescue Date::Error
    nil
  end

  def entry_year(entry)
    entry_date(entry)&.year
  end

  # Newest date first; on the same day, the higher Jira number first.
  def sort_newest_first(entries)
    entries.sort_by { |entry| sort_key(entry) }
  end

  def sort_key(entry)
    [ -(entry_date(entry)&.jd || 0), -entry[:jira_id].to_i ]
  end

  # Moves every pending entry to the top of its year's file, newest first, and
  # deletes the pending files. Each file's text is copied as is, so the rest of
  # the yearly file is never reformatted. Checks everything before writing
  # anything. Returns the number of pending files folded.
  def fold!(dir: default_dir)
    files = pending_files(dir: dir, strict: true)
    updates = files.group_by { |file| entry_year(file.entries.first) }.map do |year, group|
      path = yearly_path(year, dir: dir)
      existing = File.exist?(path) ? File.read(path) : ""
      sorted = group.sort_by { |file| sort_key(file.entries.first) }
      text = sorted.map { |file| entry_text(file.text) }.join + existing
      check_fold!(path, text, existing, sorted)
      [ path, text ]
    end

    updates.each { |path, text| File.write(path, text) }
    files.each { |file| File.delete(file.path) }
    files.size
  end

  # The pending file's text, ready to put at the top of a yearly file.
  def entry_text(text)
    lines = text.lines.reject { |line| line.match?(/\A---\s*\z/) }.drop_while { |line| line.strip.empty? }
    joined = lines.join
    joined.end_with?("\n") ? joined : "#{joined}\n"
  end

  def check_fold!(path, text, existing, files)
    expected = (existing.empty? ? 0 : Array(YAML.load(existing)).size) + files.sum { |file| file.entries.size }
    folded = YAML.load(text)
    return if folded.is_a?(Array) && folded.size == expected

    raise Error, "#{path} would not read back correctly after folding in #{files.map(&:path).join(", ")}"
  end

  # Inserts a release marker into a yearly file's text, directly above the
  # newest entry that was in the released commit. Entries above the marker
  # merged after the release. If none of this year's entries were released,
  # the marker goes at the bottom.
  def insert_release_marker(text, released_entries, version:, date:)
    text = "#{text}\n" if !text.empty? && !text.end_with?("\n")
    header, chunks = split_entries(text)
    entries = chunks.map { |chunk| YAML.load(chunk).first }

    if entries.any? { |entry| entry[:release] && entry[:release_version].to_s == version.to_s }
      raise Error, "release #{version} is already noted"
    end

    released = released_entries.reject { |entry| entry[:release] }.map { |entry| entry_key(entry) }
    index = entries.index { |entry| released.include?(entry_key(entry)) }
    if index.nil?
      raise Error, "couldn't find any of the released entries in this file" if released.any?

      index = chunks.size
    end

    marker = "- :date: #{date}\n  :release: true\n  :release_version: #{version}\n"
    header + chunks.insert(index, marker).join
  end

  # Splits a yearly file's text into any leading lines and one chunk of text
  # per entry.
  def split_entries(text)
    chunks = text.lines.slice_before { |line| line.start_with?("- ") }.map(&:join)
    header = chunks.first&.start_with?("- ") ? "" : chunks.shift.to_s
    [ header, chunks ]
  end

  def entry_key(entry)
    [ entry[:date].to_s, entry[:jira_project].to_s, entry[:jira_id].to_s, entry[:description].to_s.strip ]
  end
end
