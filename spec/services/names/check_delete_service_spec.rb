# frozen_string_literal: true

require "rails_helper"

describe Names::CheckDeleteService do
  subject(:result) { described_class.call(name: name).result }

  let(:name) { create(:name) }

  def create_referencing_name(attributes)
    referencing = build(:name,
      namespace_id: name.namespace_id,
      name_type: name.name_type,
      name_status: name.name_status,
      name_rank: name.name_rank,
      **attributes)
    referencing.save!(validate: false)
    referencing
  end

  def link_resource_to(name)
    connection = ActiveRecord::Base.connection
    site_id = connection.select_value(
      "INSERT INTO site (created_at, created_by, description, name,
                         updated_at, updated_by, url)
       VALUES (now(), 'test', 'test site', 'test site', now(), 'test',
               'http://example.com')
       RETURNING id"
    )
    resource_type_id = connection.select_value(
      "INSERT INTO resource_type (description, name)
       VALUES ('test resource type', 'test resource type')
       RETURNING id"
    )
    resource_id = connection.select_value(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO resource (created_at, created_by, path, site_id,
                                updated_at, updated_by, resource_type_id)
          VALUES (now(), 'test', 'test-path', ?, now(), 'test', ?)
          RETURNING id", site_id, resource_type_id]
      )
    )
    connection.execute(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO name_resources (name_id, resource_id) VALUES (?, ?)",
          name.id, resource_id]
      )
    )
  end

  describe "#execute" do
    context "when the name has resources" do
      before { link_resource_to(name) }

      it "blocks the delete" do
        expect(result).to be_delete_blocked
      end
    end

    %i[parent_id duplicate_of_id family_id basionym_id
      second_parent_id].each do |foreign_key|
      context "when the name is referenced via #{foreign_key} by a live name" do
        before { create_referencing_name(foreign_key => name.id) }

        it "blocks the delete" do
          expect(result).to be_delete_blocked
        end
      end
    end

    context "when the name is referenced only by a soft-deleted name" do
      before do
        create_referencing_name(parent_id: name.id)
          .update_columns(deleted_at: Time.current)
      end

      it "ignores the reference and allows a hard delete" do
        expect(result).to be_hard_delete_allowed
      end
    end

    context "when the name is referenced only by soft-deleted instances" do
      before do
        create(:instance, name: name).update_columns(deleted_at: Time.current)
      end

      it "allows a soft delete" do
        expect(result).to be_soft_delete_allowed
      end
    end

    context "when the name has no resources, references or instances" do
      it "allows a hard delete" do
        expect(result).to be_hard_delete_allowed
      end
    end

    context "when the name is referenced by a live instance" do
      before { create(:instance, name: name) }

      it "blocks the delete" do
        expect(result).to be_delete_blocked
      end
    end

    context "when the name has both live and soft-deleted instances" do
      before do
        create(:instance, name: name).update_columns(deleted_at: Time.current)
        create(:instance, name: name,
          instance_type: create(:instance_type, primary_instance: false))
      end

      it "blocks the delete" do
        expect(result).to be_delete_blocked
      end
    end
  end
end
