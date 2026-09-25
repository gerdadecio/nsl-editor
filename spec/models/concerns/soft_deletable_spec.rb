# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples("a soft deletable model") do
  let(:allowed_result) do
    double(
      "CheckDeleteResult",
      soft_delete_allowed?: true,
      explanation: "used only in past tree versions",
    )
  end
  let(:blocked_result) do
    double(
      "CheckDeleteResult",
      soft_delete_allowed?: false,
      explanation: "referenced by a live record",
    )
  end

  before do
    allow(Rails.configuration).to(receive(:try).and_call_original)
    allow(Rails.configuration).to(receive(:try)
      .with(:soft_delete_enabled).and_return(true))
  end

  describe "#soft_deleted?" do
    it "is false while deleted_at is nil" do
      expect(record).not_to(be_soft_deleted)
    end

    it "is true once deleted_at is set" do
      record.deleted_at = Time.current
      expect(record).to(be_soft_deleted)
    end
  end

  describe "#soft_deleting?" do
    it "is false when deleted_at is untouched" do
      expect(record).not_to(be_soft_deleting)
    end

    it "is true when deleted_at is being set" do
      record.deleted_at = Time.current
      expect(record).to(be_soft_deleting)
    end

    it "is false when deleted_at is being cleared" do
      record.update_columns(deleted_at: 1.day.ago)
      record.reload.deleted_at = nil
      expect(record).not_to(be_soft_deleting)
    end
  end

  describe "validation when deleted_at is set on a persisted record" do
    context "when the check delete rules allow a soft delete" do
      before { allow(record).to(receive(:check_delete_result).and_return(allowed_result)) }

      it "saves and records the deleted_at timestamp" do
        record.deleted_at = Time.current

        expect(record.save).to(be(true))
        expect(record.reload.deleted_at).to(be_present)
      end
    end

    context "when the check delete rules do not allow a soft delete" do
      before { allow(record).to(receive(:check_delete_result).and_return(blocked_result)) }

      it "refuses to save and reports the database's explanation" do
        record.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base])
          .to(include("Soft delete not allowed: referenced by a live record"))
        expect(record.reload.deleted_at).to(be_nil)
      end
    end

    context "when soft delete is not enabled" do
      before do
        allow(Rails.configuration).to(receive(:try)
          .with(:soft_delete_enabled).and_return(false))
      end

      it "refuses to save without consulting the check delete rules" do
        expect(record).not_to(receive(:check_delete_result))
        record.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base]).to(include("Soft delete is not enabled"))
      end
    end

    context "when the record is already soft deleted" do
      before { record.update_columns(deleted_at: 1.day.ago) }

      it "refuses to move the deleted_at timestamp" do
        expect(record).not_to(receive(:check_delete_result))
        record.reload.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base])
          .to(include("#{record.model_name.human} is already soft deleted"))
      end
    end
  end

  describe "saves that do not touch deleted_at" do
    it "does not consult the check delete rules" do
      expect(record).not_to(receive(:check_delete_result))
      record.updated_by = "someone else"

      expect(record.save).to(be(true))
    end

    it "allows deleted_at to be cleared again" do
      record.update_columns(deleted_at: 1.day.ago)
      expect(record).not_to(receive(:check_delete_result))
      record.reload.deleted_at = nil

      expect(record.save).to(be(true))
      expect(record.reload.deleted_at).to(be_nil)
    end
  end
end

RSpec.describe(SoftDeletable, type: :model) do
  describe "Name" do
    let(:record) { create(:name) }

    it_behaves_like "a soft deletable model"

    describe "against the check_delete_name database function" do
      before do
        allow(Rails.configuration).to(receive(:try).and_call_original)
        allow(Rails.configuration).to(receive(:try)
          .with(:soft_delete_enabled).and_return(true))
      end

      it "refuses a name that has no instances - it should be hard deleted" do
        record.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base])
          .to(include("Soft delete not allowed: Name is not referenced by any instance"))
      end

      it "refuses a name that still has a live instance" do
        create(:instance, name: record)
        record.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base])
          .to(include("Soft delete not allowed: Name is referenced by a live instance"))
      end

      it "allows a name whose only instances are soft deleted" do
        create(:instance, name: record, deleted_at: Time.current)
        record.deleted_at = Time.current

        expect(record.save).to(be(true))
        expect(record.reload).to(be_soft_deleted)
      end
    end
  end

  describe "Instance" do
    let(:record) { create(:instance, name: create(:name)) }

    it_behaves_like "a soft deletable model"

    describe "against the check_delete_instance database function" do
      before do
        allow(Rails.configuration).to(receive(:try).and_call_original)
        allow(Rails.configuration).to(receive(:try)
          .with(:soft_delete_enabled).and_return(true))
      end

      it "refuses an instance with no tree dependents - it should be hard deleted" do
        record.deleted_at = Time.current

        expect(record.save).to(be(false))
        expect(record.errors[:base])
          .to(include("Soft delete not allowed: Instance has no instance or tree dependents"))
      end
    end
  end

  describe "#check_delete_result" do
    it "raises when the including model does not implement it" do
      klass = Class.new(ActiveRecord::Base) do
        self.table_name = "name"
        include SoftDeletable

        def self.name = "Anonymous"
      end

      expect { klass.new.check_delete_result }
        .to(raise_error(NotImplementedError, /must implement #check_delete_result/))
    end
  end
end
