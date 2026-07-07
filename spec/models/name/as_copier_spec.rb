require "rails_helper"

RSpec.describe Name::AsCopier, type: :model do
  let!(:na_status) { FactoryBot.create(:name_status, name: "[n/a]") }

  let(:hybrid_type)     { FactoryBot.create(:name_type, hybrid: true) }
  let(:non_hybrid_type) { FactoryBot.create(:name_type, hybrid: false) }

  before do
    allow_any_instance_of(Name).to receive(:set_names!)
    allow_any_instance_of(Name).to receive(:refresh_name_paths)
  end

  describe "#copy_with_username" do
    it "raises when the new name element equals the original" do
      source = described_class.find(
        FactoryBot.create(:name, name_type: non_hybrid_type, name_element: "same").id
      )

      expect { source.copy_with_username("same", "tester") }
        .to raise_error("Copied record would have the same name.")
    end

    context "when the source name is not a hybrid" do
      let(:legit)  { FactoryBot.create(:name_status, name: "legitimate") }
      let(:source) do
        described_class.find(
          FactoryBot.create(:name, name_type: non_hybrid_type,
                                   name_status: legit, name_element: "orig").id
        )
      end

      it "keeps the duplicated status (does NOT force [n/a])" do
        copy = source.copy_with_username("newelement", "tester")
        expect(copy.name_status).to eq(legit)
      end

      it "resets uri, source fields and lock_version on the copy" do
        copy = source.copy_with_username("newelement", "tester")

        aggregate_failures do
          expect(copy.uri).to be_nil
          expect(copy.source_system).to be_nil
          expect(copy.source_id_string).to be_nil
          expect(copy.source_id).to be_nil
          expect(copy.lock_version).to eq(0)
          expect(copy.created_by).to eq("tester")
          expect(copy.updated_by).to eq("tester")
        end
      end
    end

    context "when the source name is a hybrid" do
      let(:first_parent)  { FactoryBot.create(:name) }
      let(:second_parent) { FactoryBot.create(:name) }
      let(:source) do
        described_class.find(
          FactoryBot.create(:name, name_type: non_hybrid_type, name_element: "orig").id
        )
      end

      before do
        allow(source).to receive(:hybrid?).and_return(true)
        allow(source).to receive(:cultivar_hybrid?).and_return(false)
      end

      def copy_with(parent_id:, second_parent_id:)
        source.copy_with_username("newelement", "tester",
                                  parent_id: parent_id,
                                  second_parent_id: second_parent_id)
      end

      context "with two valid, distinct parents" do
        before do
          allow_any_instance_of(Name).to receive(:takes_parent_2?).and_return(true)
        end

        it "forces the copy's status to [n/a]" do
          copy = copy_with(parent_id: first_parent.id,
                           second_parent_id: second_parent.id)
          expect(copy.name_status).to eq(na_status)
        end

        it "assigns the chosen parents to the copy" do
          copy = copy_with(parent_id: first_parent.id,
                           second_parent_id: second_parent.id)

          aggregate_failures do
            expect(copy.parent_id).to eq(first_parent.id)
            expect(copy.second_parent_id).to eq(second_parent.id)
          end
        end
      end

      it "raises when the first parent is blank" do
        expect { copy_with(parent_id: nil, second_parent_id: second_parent.id) }
          .to raise_error(/first parent that is different/)
      end

      it "raises when the second parent is blank" do
        expect { copy_with(parent_id: first_parent.id, second_parent_id: nil) }
          .to raise_error(/second parent that is different/)
      end

      it "raises when both parents are the same (non cultivar-hybrid)" do
        expect { copy_with(parent_id: first_parent.id, second_parent_id: first_parent.id) }
          .to raise_error("The second parent cannot be the same as the first parent.")
      end
    end
  end
end
