# frozen_string_literal: true

require "rails_helper"

RSpec.describe(BootstrapUpgradeHelper, type: :helper) do
  # Matches the implementation, which reads the flag via
  # `Rails.configuration.try("use_latest_bootstrap_version")`.
  def stub_flag(value)
    allow(Rails.configuration).to receive(:try)
      .with(:use_latest_bootstrap_version)
      .and_return(value)
  end

  describe "#bootstrap5?" do
    it "is true when the flag is set to true" do
      stub_flag(true)
      expect(helper.bootstrap5?).to be true
    end

    it "is false when the flag is set to false" do
      stub_flag(false)
      expect(helper.bootstrap5?).to be false
    end

    it "is false when the flag is unset (nil)" do
      stub_flag(nil)
      expect(helper.bootstrap5?).to be false
    end

    it "is false for truthy-but-not-true values" do
      stub_flag("true")
      expect(helper.bootstrap5?).to be false
    end
  end

  describe "#bs_toggle" do
    context "when the flag is off (Bootstrap 3)" do
      before { stub_flag(false) }

      it "emits the unprefixed data-toggle attribute" do
        expect(helper.bs_toggle(:dropdown)).to eq('data-toggle="dropdown"')
      end

      it "emits matching data-toggle and data-target when a target is given" do
        expect(helper.bs_toggle(:collapse, target: ".navbar-collapse"))
          .to eq('data-toggle="collapse" data-target=".navbar-collapse"')
      end

      it "omits the target attribute when target is nil" do
        expect(helper.bs_toggle(:collapse)).to eq('data-toggle="collapse"')
      end
    end

    context "when the flag is on (Bootstrap 5)" do
      before { stub_flag(true) }

      it "emits the data-bs-prefixed toggle attribute" do
        expect(helper.bs_toggle(:dropdown)).to eq('data-bs-toggle="dropdown"')
      end

      it "emits matching data-bs-toggle and data-bs-target when a target is given" do
        expect(helper.bs_toggle(:collapse, target: ".navbar-collapse"))
          .to eq('data-bs-toggle="collapse" data-bs-target=".navbar-collapse"')
      end

      it "omits the target attribute when target is nil" do
        expect(helper.bs_toggle(:collapse)).to eq('data-bs-toggle="collapse"')
      end
    end

    it "returns an html_safe string so it is not escaped in views" do
      stub_flag(true)
      expect(helper.bs_toggle(:dropdown)).to be_html_safe
    end
  end

  describe "#navbar_toggle_class" do
    it "returns navbar-toggle when the flag is off" do
      stub_flag(false)
      expect(helper.navbar_toggle_class).to eq("navbar-toggle")
    end

    it "returns navbar-toggler when the flag is on" do
      stub_flag(true)
      expect(helper.navbar_toggle_class).to eq("navbar-toggler")
    end
  end
end
