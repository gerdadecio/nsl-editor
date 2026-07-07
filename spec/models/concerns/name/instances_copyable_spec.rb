require "rails_helper"

RSpec.describe Name::InstancesCopyable, type: :model do
  let(:name) { FactoryBot.create(:name) }

  def standalone_instance_for(target_name, iso:)
    reference = FactoryBot.create(:reference, iso_publication_date: iso)
    instance_type = FactoryBot.create(:instance_type, standalone: true,
                                                      primary_instance: false)
    FactoryBot.create(:instance, name: target_name, reference: reference,
                                 instance_type: instance_type)
  end

  describe "#standalone_instances_sorted" do
    it "does not raise when a reference has a nil iso_publication_date" do
      standalone_instance_for(name, iso: "2001-01-01")
      standalone_instance_for(name, iso: nil)

      expect { name.standalone_instances_sorted }.not_to raise_error
    end

    it "orders by iso_publication_date with nil sorting first" do
      later   = standalone_instance_for(name, iso: "2010")
      undated = standalone_instance_for(name, iso: nil)
      earlier = standalone_instance_for(name, iso: "2000")

      expect(name.standalone_instances_sorted).to eq([undated, earlier, later])
    end

    it "returns an empty array when there are no standalone instances" do
      expect(name.standalone_instances_sorted).to eq([])
    end
  end
end
