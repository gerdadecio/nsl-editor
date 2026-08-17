# frozen_string_literal: true

require "rails_helper"

RSpec.describe NameRank, type: :model do
  # Every rank here is built with a display_name that differs from its name, so
  # each example proves which column the option label comes from.
  let(:name_group) { create(:name_group) }

  def build_rank(name, sort_order, deprecated: false)
    create(
      :name_rank,
      name: name,
      display_name: "#{name} display",
      sort_order: sort_order,
      deprecated: deprecated,
      name_group: name_group
    )
  end

  let!(:regnum) { build_rank("Regnum", 10) }
  let!(:familia) { build_rank("Familia", 20) }
  let!(:genus) { build_rank("Genus", 30) }
  let!(:species) { build_rank("Species", 40) }
  let!(:varietas) { build_rank("Varietas", 50) }
  let!(:unranked) { build_rank("[unranked]", 60) }
  let!(:infraspecies) { build_rank("[infraspecies]", 70) }
  let!(:deprecated_forma) { build_rank("Forma", 80, deprecated: true) }

  describe "#below_family?" do
    it "is true for a rank sorted below family" do
      expect(genus).to be_below_family
      expect(species).to be_below_family
    end

    it "is false for the family rank itself" do
      expect(familia).not_to be_below_family
    end

    it "is false for a rank sorted above family" do
      expect(regnum).not_to be_below_family
    end

    context "when there is no family rank" do
      before { described_class.where(name: "Familia").delete_all }

      it "is false instead of raising" do
        expect { genus.below_family? }.not_to raise_error
        expect(genus).not_to be_below_family
      end

      it "lets #parent fall back to no parent" do
        expect(genus.parent).to be_a NoParent
      end

      it "lets .options_for_category return rank options instead of raising" do
        scientific = create(:name_category, valid_names: ["scientific"])

        expect { described_class.options_for_category(scientific, genus) }
          .not_to raise_error
      end
    end
  end

  describe ".below_family_options" do
    subject(:options) { described_class.below_family_options }

    it "labels each option with the rank name, not the display name" do
      expect(options).to eq [
        ["Genus", genus.id],
        ["Species", species.id],
        ["Varietas", varietas.id],
        ["[unranked]", unranked.id],
        ["[infraspecies]", infraspecies.id]
      ]
    end

    it "excludes ranks at or above family" do
      expect(options.collect(&:first)).not_to include("Familia", "Regnum")
    end

    it "excludes deprecated ranks" do
      expect(options.collect(&:first)).not_to include("Forma")
    end
  end

  describe ".above_family_options" do
    subject(:options) { described_class.above_family_options }

    it "labels each option with the rank name, not the display name" do
      expect(options).to eq [
        ["Regnum", regnum.id],
        ["Familia", familia.id]
      ]
    end

    it "excludes ranks below family" do
      expect(options.collect(&:first)).not_to include("Genus", "Species")
    end
  end

  describe ".cultivar_options" do
    subject(:options) { described_class.cultivar_options }

    it "labels each option with the rank name, not the display name" do
      expect(options).to eq [
        ["Species", species.id],
        ["Varietas", varietas.id],
        ["[unranked]", unranked.id]
      ]
    end

    it "excludes bracketed ranks other than [unranked]" do
      expect(options.collect(&:first)).not_to include("[infraspecies]")
    end

    it "excludes ranks above species" do
      expect(options.collect(&:first)).not_to include("Genus", "Familia")
    end
  end

  describe ".cultivar_hybrid_options" do
    subject(:options) { described_class.cultivar_hybrid_options }

    it "labels each option with the rank name, not the display name" do
      expect(options).to eq [
        ["Species", species.id],
        ["Varietas", varietas.id],
        ["[unranked]", unranked.id]
      ]
    end

    it "excludes bracketed ranks other than [unranked]" do
      expect(options.collect(&:first)).not_to include("[infraspecies]")
    end
  end

  describe ".options_for_category" do
    let(:scientific) { create(:name_category, valid_names: ["scientific"]) }

    it "uses the below-family options when the current rank is below family" do
      options = described_class.options_for_category(scientific, species)

      expect(options).to eq described_class.below_family_options
      expect(options.collect(&:first)).to include("Genus", "Species")
    end

    it "uses the above-family options when the current rank is family" do
      options = described_class.options_for_category(scientific, familia)

      expect(options).to eq described_class.above_family_options
      expect(options.collect(&:first)).to eq %w[Regnum Familia]
    end
  end

  describe ".options" do
    it "still labels each option with the display name" do
      expect(described_class.options).to eq [
        ["Regnum display", regnum.id],
        ["Familia display", familia.id],
        ["Genus display", genus.id],
        ["Species display", species.id],
        ["Varietas display", varietas.id],
        ["[unranked] display", unranked.id],
        ["[infraspecies] display", infraspecies.id]
      ]
    end
  end
end
