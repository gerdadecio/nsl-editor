require 'rails_helper'

RSpec.describe Instance::AsCopier, type: :model do
  subject { described_class.new }

  describe "#copy_with_product_reference" do
    context "with invalid arguments" do
      it "raises an error" do
        expect{described_class.new.copy_with_product_reference}.to raise_error(ArgumentError)
      end
    end

    context "with valid arguments" do
      let(:params) { {} }
      let(:username) { "username" }

      let!(:language) { FactoryBot.create(:language, iso6391code: "en", iso6393code: "eng") }
      let!(:reference) { FactoryBot.create(:reference, language: language) }
      let(:name_category) { FactoryBot.create(:name_category, name: "other") }
      let(:name_type) { FactoryBot.create(:name_type, cultivar: false, name_category: name_category) }
      let(:name) { FactoryBot.create(:name, name_type: name_type) }

      let(:instance_type) { FactoryBot.create(:instance_type, primary_instance: false)}
      let(:instance) { FactoryBot.create(:instance, reference: reference, instance_type_id: instance_type.id) }

      let(:instance_citation) { FactoryBot.create(:instance, :synonym_instance, name: name, reference: reference) }

      context "with invalid parameters" do
        it "raises an error for blank reference_id" do
          expect{subject.copy_with_product_reference(params, username)}.to raise_error(RuntimeError, "Need a reference")
        end

        it "raises an error for non-integer reference_id" do
          expect{subject.copy_with_product_reference({reference_id: "a"}, username)}.to raise_error(RuntimeError, "Unrecognized reference id")
        end

        it "raises an error for when a reference does not exists" do
          non_existent_reference_id = reference.id + 1
          expect{subject.copy_with_product_reference({reference_id: non_existent_reference_id}, username)}.to raise_error(RuntimeError, "No such ref")
        end
      end

      context "for valid parameters" do
        let(:instance_type) { FactoryBot.create(:instance_type, name: "another name")}
        let(:params) do
          {
            reference_id: reference.id,
            instance_type_id: instance_type.id,
            draft: true
          }
        end

        subject { described_class.find(instance.id) }

        before do
          subject.multiple_primary_override = true
          subject.duplicate_instance_override = true
        end

        it "creates a copy of the instance" do
          copied_instance = subject.copy_with_product_reference(params,username)
          excluded_attributes = [
            "id", "created_at", "created_by", "updated_at", "instance_type_id",
            "lock_version", "reference_id", "source_id_string", "source_system",
            "page_qualifier", "page", "updated_at", "updated_by"
          ]
          expect(copied_instance.attributes.except(*excluded_attributes)).to eq(subject.attributes.except(*excluded_attributes))
          expect(copied_instance.class).to eq Instance::AsCopier
        end

        it "creates a copy of the instance's citations" do
          instance.update(cited_by_id: instance_citation.id)
          instance.reload
          instance_citation.multiple_primary_override = true
          subj = described_class.find(instance.id)
          subj.multiple_primary_override = true
          subj.duplicate_instance_override = true

          allow(subj).to receive(:reverse_of_this_is_cited_by).and_return([instance_citation])
          copied_instance = subj.copy_with_product_reference(params,username)
          copied_citation = copied_instance.reverse_of_this_is_cited_by.first
          expect(copied_citation.name_id).to eq instance_citation.name_id
          expect(copied_citation.reference_id).to eq reference.id
          expect(copied_citation.cited_by_id).to eq copied_instance.id
          expect(copied_citation.cites_id).to eq instance_citation.cites_id
          expect(copied_citation.instance_type_id).to eq instance_citation.instance_type_id
          expect(copied_citation.verbatim_name_string).to eq instance_citation.verbatim_name_string
          expect(copied_citation.bhl_url).to eq instance_citation.bhl_url
          expect(copied_citation.created_by).to eq "username"
        end

        context "when copy_profile_items? is true" do
          let(:profile_item) { FactoryBot.create(:profile_item, instance: instance) }
          before do
            allow(subject).to receive(:copy_profile_items).and_return(true)
            allow(subject).to receive(:profile_items).and_return([profile_item])
            allow_any_instance_of(Profile::ProfileItem).to receive(:fact?).and_return(true)
          end

          it "copies the profile items" do
            copied_instance = subject.copy_with_product_reference(params, username)
            copied_profile_item = copied_instance.profile_items.first
            expect(copied_profile_item.source_profile_item_id).to eq profile_item.id
            expect(copied_profile_item.product_item_config_id).to eq profile_item.product_item_config_id
            expect(copied_profile_item.is_draft).to be true
            expect(copied_profile_item.statement_type).to eq "link"
            expect(copied_profile_item.source_id).to be_nil
            expect(copied_profile_item.published_date).to be_nil
            expect(copied_profile_item.source_id_string).to be_nil
            expect(copied_profile_item.tree_element_id).to be_nil
            expect(copied_profile_item.source_system).to be_nil
            expect(copied_profile_item.created_by).to eq username
            expect(copied_profile_item.updated_by).to eq username
          end

          context "when profile item is not a fact" do
            before do
              allow_any_instance_of(Profile::ProfileItem).to receive(:fact?).and_return(false)
            end

            it "sets the copied profile item's source_profile_item_id to nil" do
              copied_instance = subject.copy_with_product_reference(params, username)
              copied_profile_item = copied_instance.profile_items.first
              expect(copied_profile_item.source_profile_item_id).to eq nil
            end
          end
        end

        context "when copy_profile_items? is false" do
          let(:profile_item) { FactoryBot.create(:profile_item, instance: instance) }

          before do
            allow(subject).to receive(:copy_profile_items).and_return(false)
            allow(subject).to receive(:profile_items).and_return([profile_item])
          end

          it "does not copy the profile items" do
            copied_instance = subject.copy_with_product_reference(params, username)
            expect(copied_instance.profile_items).to be_empty
          end
        end
      end
    end
  end
end
