# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  let(:root_url) { "https://services.example/nsl/services/" }

  before do
    allow(Rails.configuration).to receive(:try).and_call_original
    allow(Rails.configuration).to receive(:try).with(:services_clientside_root_url).and_return(root_url)
    allow(Rails.configuration).to receive(:try).with(:services_product).and_return(nil)
  end

  describe "#admin_services_product" do
    it "defaults to apni when no product is configured" do
      expect(helper.admin_services_product).to eq("apni")
    end

    it "uses the configured product" do
      allow(Rails.configuration).to receive(:try).with(:services_product).and_return("afd")
      expect(helper.admin_services_product).to eq("afd")
    end
  end

  describe "#admin_sample_name_id" do
    it "returns the lowest name id as an Integer" do
      allow(Name).to receive(:minimum).with(:id).and_return(42)
      expect(helper.admin_sample_name_id).to eq(42)
    end

    it "returns 0 when there are no names" do
      allow(Name).to receive(:minimum).with(:id).and_return(nil)
      expect(helper.admin_sample_name_id).to eq(0)
    end

    it "raises rather than rendering a non-numeric id" do
      allow(Name).to receive(:minimum).with(:id).and_return("1<script>")
      expect { helper.admin_sample_name_id }.to raise_error(ArgumentError)
    end
  end

  describe "#admin_service_url" do
    before { allow(Name).to receive(:minimum).with(:id).and_return(7) }

    it "builds a name service url" do
      expect(helper.admin_service_url("name", "apc.json"))
        .to eq("#{root_url}rest/name/apni/7/api/apc.json")
    end

    it "builds a reference service url with the configured product" do
      allow(Rails.configuration).to receive(:try).with(:services_product).and_return("afd")
      expect(helper.admin_service_url("reference", "citation-strings.json"))
        .to eq("#{root_url}rest/reference/afd/7/api/citation-strings.json")
    end

    it "tolerates a missing root url" do
      allow(Rails.configuration).to receive(:try).with(:services_clientside_root_url).and_return(nil)
      expect(helper.admin_service_url("name", "apc.json")).to eq("rest/name/apni/7/api/apc.json")
    end
  end
end
