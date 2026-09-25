# frozen_string_literal: true

require "rails_helper"

# Exercised through Instance#parent, the simplest association it guards.
RSpec.describe RejectsSoftDeletedLinks do
  let(:live_parent) { create(:instance) }
  let(:soft_deleted_parent) { create(:instance, deleted_at: Time.current) }
  let(:message) { "The parent instance has been soft deleted and cannot be used" }

  def base_errors(record)
    record.valid?
    record.errors[:base]
  end

  context "when linking a new record" do
    it "rejects a soft deleted target" do
      instance = build(:instance, parent: soft_deleted_parent)
      expect(base_errors(instance)).to include(message)
    end

    it "accepts a live target" do
      instance = build(:instance, parent: live_parent)
      expect(base_errors(instance)).not_to include(message)
    end

    it "accepts no target" do
      instance = build(:instance, parent: live_parent)
      instance.parent = nil
      expect(base_errors(instance)).not_to include(message)
    end
  end

  context "when updating an existing record" do
    let(:instance) { create(:instance) }

    it "rejects changing the link to a soft deleted target" do
      instance.parent_id = soft_deleted_parent.id
      expect(base_errors(instance)).to include(message)
    end

    it "keeps a link made before the target was soft deleted" do
      instance.update_column(:parent_id, live_parent.id)
      live_parent.update_column(:deleted_at, Time.current)
      instance.reload.page = "a different page"
      expect(base_errors(instance)).not_to include(message)
    end
  end

  it "raises when declared with an unknown association" do
    expect do
      Class.new(ApplicationRecord) do
        self.table_name = "instance"
        include RejectsSoftDeletedLinks

        rejects_soft_deleted_links no_such_link: "missing link"
      end
    end.to raise_error(ArgumentError, /no association :no_such_link/)
  end

  it "does not load the association when its foreign key is unchanged" do
    instance = create(:instance)
    instance.reload
    expect(instance).not_to receive(:parent)
    instance.valid?
  end
end
