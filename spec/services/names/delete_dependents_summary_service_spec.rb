# frozen_string_literal: true

require "rails_helper"

describe Names::DeleteDependentsSummaryService do
  subject(:service) { described_class.call(name: name) }

  let(:name) { create(:name) }
  let(:other_name) { create(:name) }

  def group_for(label)
    service.groups.find { |group| group.label == label }
  end

  def connection
    ActiveRecord::Base.connection
  end

  def site_id
    @site_id ||= connection.select_value(
      "INSERT INTO site (created_at, created_by, description, name,
                         updated_at, updated_by, url)
       VALUES (now(), 'test', 'test site', 'test site', now(), 'test',
               'http://example.com')
       RETURNING id"
    )
  end

  def resource_type_id_for(description)
    resource_type_ids[description] ||= connection.select_value(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO resource_type (description, name)
          VALUES (?, ?)
          RETURNING id", description, "#{description} #{resource_type_ids.size}"]
      )
    )
  end

  def resource_type_ids
    @resource_type_ids ||= {}
  end

  def link_resource_to(a_name, type_description:)
    resource_id = connection.select_value(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO resource (created_at, created_by, path, site_id,
                                updated_at, updated_by, resource_type_id)
          VALUES (now(), 'test', 'test-path', ?, now(), 'test', ?)
          RETURNING id", site_id, resource_type_id_for(type_description)]
      )
    )
    connection.execute(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO name_resources (name_id, resource_id) VALUES (?, ?)",
          a_name.id, resource_id]
      )
    )
  end

  def add_name_resource_to(a_name, host_name:)
    create(:name_resource,
      name: a_name,
      resource_host: create(:resource_host, name: host_name))
  end

  def create_name_tag(tag_name)
    name_tag = build(:name_tag, name: tag_name)
    name_tag.save!(validate: false)
    name_tag
  end

  def tag(a_name, tag_name:)
    create(:name_tag_name,
      name_id: a_name.id,
      tag_id: create_name_tag(tag_name).id)
  end

  describe "#execute" do
    context "when the name has no dependents" do
      it "produces no groups" do
        expect(service.groups).to be_empty
      end

      it "is not any?" do
        expect(service).not_to be_any
      end
    end

    context "when the name has name_resource records" do
      before do
        add_name_resource_to(name, host_name: "IPNI")
        add_name_resource_to(name, host_name: "BHL")
      end

      it "counts them by resource host name, ordered by host name" do
        expect(group_for("Name resources").entries)
          .to eq([["BHL", 1], ["IPNI", 1]])
      end

      it "totals the entries" do
        expect(group_for("Name resources").total).to eq(2)
      end

      it "is any?" do
        expect(service).to be_any
      end

      it "does not report the other groups" do
        expect(service.groups.map(&:label)).to eq(["Name resources"])
      end
    end

    context "when a resource host has no name" do
      before do
        add_name_resource_to(name, host_name: nil)
        add_name_resource_to(name, host_name: nil)
      end

      it "labels the entry as unnamed and counts them together" do
        expect(group_for("Name resources").entries)
          .to eq([[described_class::UNLABELLED, 2]])
      end
    end

    context "when the name has name_resources rows" do
      before do
        link_resource_to(name, type_description: "Protologue")
        link_resource_to(name, type_description: "Protologue")
        link_resource_to(name, type_description: "Biodiversity Heritage Library")
      end

      it "counts them by resource type, ordered by description" do
        expect(group_for("Resources").entries)
          .to eq([["Biodiversity Heritage Library", 1], ["Protologue", 2]])
      end

      it "totals the entries" do
        expect(group_for("Resources").total).to eq(3)
      end
    end

    context "when the name has tags" do
      before do
        tag(name, tag_name: "vetted")
        tag(name, tag_name: "ambiguous")
      end

      it "counts them by tag, ordered by tag name" do
        expect(group_for("Name tags").entries)
          .to eq([["ambiguous", 1], ["vetted", 1]])
      end

      it "totals the entries" do
        expect(group_for("Name tags").total).to eq(2)
      end
    end

    # name_resources is legacy and is expected to be dropped. Postgres DDL is
    # transactional, so the table is really dropped here and the example's
    # transaction puts it back.
    context "when the name_resources table has been dropped" do
      before do
        add_name_resource_to(name, host_name: "IPNI")
        tag(name, tag_name: "vetted")
        connection.execute("DROP TABLE name_resources")
      end

      it "leaves the resources group out instead of raising" do
        expect(service.groups.map(&:label))
          .to eq(["Name resources", "Name tags"])
      end
    end

    context "when the resource table has been dropped" do
      before { connection.execute("DROP TABLE resource CASCADE") }

      it "leaves the resources group out instead of raising" do
        expect(service.groups).to be_empty
      end
    end

    context "when the dependents belong to another name" do
      before do
        add_name_resource_to(other_name, host_name: "IPNI")
        link_resource_to(other_name, type_description: "Protologue")
        tag(other_name, tag_name: "vetted")
      end

      it "produces no groups for this name" do
        expect(service.groups).to be_empty
      end
    end

    context "when the name has every kind of dependent" do
      before do
        add_name_resource_to(name, host_name: "IPNI")
        link_resource_to(name, type_description: "Protologue")
        tag(name, tag_name: "vetted")
      end

      it "reports the groups in a fixed order" do
        expect(service.groups.map(&:label))
          .to eq(["Name resources", "Resources", "Name tags"])
      end

      it "counts each group separately" do
        expect(service.groups.map(&:total)).to eq([1, 1, 1])
      end
    end
  end
end
