# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditHelper, type: :helper do
  def normalize(str)
    Nokogiri::HTML.fragment(str).text.squish
  end

  describe "#created_by_whom_and_when" do
    it "shows who created the record and when" do
      record = double("Record", created_at: 2.days.ago, created_by: "alice")
      expect(normalize(helper.created_by_whom_and_when(record))).to match(/\ACreated 2 days ago by alice .+\z/)
    end
  end

  describe "#updated_by_whom_and_when" do
    it "shows update info when meaningfully updated" do
      record = double("Record", created_at: 1.day.ago, updated_at: 1.hour.ago, updated_by: "bob")
      expect(normalize(helper.updated_by_whom_and_when(record))).to match(/\ALast updated about 1 hour ago by bob .+\z/)
    end

    it "says not updated when timestamps are within the threshold" do
      base = Time.zone.parse("2026-01-15 12:00:00")
      record = double("Record", created_at: base, updated_at: base + 5.seconds)
      expect(helper.updated_by_whom_and_when(record)).to eq("Not updated since it was created.")
    end
  end

  describe "#meaningful_update_when_no_created_at" do
    it "shows 'Created or last updated' with who and when" do
      record = double("Record", updated_at: 4.days.ago, updated_by: "system")
      expect(normalize(helper.meaningful_update_when_no_created_at(record))).to match(/\ACreated or last updated 4 days ago by system .+\z/)
    end
  end

  describe "#profile_item_created_audit" do
    let(:profile_text) { double("ProfileText", created_at: 1.week.ago, created_by: "author") }

    it "shows 'as original content' for facts" do
      item = double("ProfileItem", fact?: true, profile_text: profile_text)
      expect(normalize(helper.profile_item_created_audit(item))).to match(/\ACreated 7 days ago by author .+ as original content\z/)
    end

    it "shows quoted content message for non-facts" do
      item = double("ProfileItem", fact?: false, profile_text: profile_text)
      expect(normalize(helper.profile_item_created_audit(item))).to match(/\Acreated 7 days ago by author .+\z/)
    end
  end

  describe "#profile_item_updated_audit" do
    it "shows update with 'as original content' for updated facts" do
      text = double("ProfileText", created_at: 1.week.ago, updated_at: 1.day.ago, updated_by: "editor")
      item = double("ProfileItem", fact?: true, profile_text: text)
      expect(normalize(helper.profile_item_updated_audit(item))).to match(/\ALast updated 1 day ago by editor .+ as original content\z/)
    end

    it "says not updated for facts with no meaningful update" do
      base = Time.zone.parse("2026-01-15 12:00:00")
      text = double("ProfileText", created_at: base, updated_at: base + 5.seconds, updated_by: "editor")
      item = double("ProfileItem", fact?: true, profile_text: text)
      expect(helper.profile_item_updated_audit(item)).to eq("Not updated since it was created.")
    end

    it "shows quoted content message for non-facts" do
      text = double("ProfileText", updated_at: 1.day.ago, updated_by: "editor")
      item = double("ProfileItem", fact?: false, profile_text: text)
      expect(normalize(helper.profile_item_updated_audit(item))).to match(/\Aupdated 1 day ago by editor .+\z/)
    end
  end

  describe "#published_by_whom_and_when" do
    it "shows published info using published_at and published_by" do
      record = double("Record", published_at: 3.days.ago, published_by: "publisher", updated_by: "updater")
      allow(record).to receive(:respond_to?).with(:published_at).and_return(true)
      allow(record).to receive(:respond_to?).with(:published_date).and_return(false)
      allow(record).to receive(:respond_to?).with(:published_by).and_return(true)

      expect(normalize(helper.published_by_whom_and_when(record))).to match(/\APublished 3 days ago by publisher .+\z/)
    end

    it "falls back to published_date and updated_by when needed" do
      record = double("Record", published_date: 5.days.ago, updated_by: "updater")
      allow(record).to receive(:respond_to?).with(:published_at).and_return(false)
      allow(record).to receive(:respond_to?).with(:published_date).and_return(true)
      allow(record).to receive(:respond_to?).with(:published_by).and_return(false)

      expect(normalize(helper.published_by_whom_and_when(record))).to match(/\APublished 5 days ago by updater .+\z/)
    end

    it "returns empty string when no published timestamp exists" do
      record = double("Record", updated_by: "updater")
      allow(record).to receive(:respond_to?).with(:published_at).and_return(false)
      allow(record).to receive(:respond_to?).with(:published_date).and_return(false)

      expect(helper.published_by_whom_and_when(record)).to eq("")
    end

    it "falls back to published_date when published_at is nil" do
      record = double("Record", published_at: nil, published_date: 1.week.ago, updated_by: "updater")
      allow(record).to receive(:respond_to?).with(:published_at).and_return(true)
      allow(record).to receive(:respond_to?).with(:published_date).and_return(true)
      allow(record).to receive(:respond_to?).with(:published_by).and_return(false)

      expect(normalize(helper.published_by_whom_and_when(record))).to match(/\APublished 7 days ago by updater .+\z/)
    end
  end
end
