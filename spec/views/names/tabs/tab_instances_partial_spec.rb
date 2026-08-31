# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_instances.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    # Ability#soft_deleted_name_auth grants :modify to everyone and withdraws
    # it once the name is soft deleted.
    allow(view).to receive(:can?).with(:modify, name) { name.deleted_at.blank? }
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "instances/_form_create_from_name.html.erb" => '<div id="instance-form-stub"></div>'
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_instances" }

  context "when the name has not been soft deleted" do
    it "renders the add an instance form" do
      subject
      expect(rendered).to have_selector("h5", text: "Add an instance")
      expect(rendered).to have_selector("#instance-form-stub")
    end

    context "and the name is a duplicate" do
      before { allow(name).to receive(:duplicate?).and_return(true) }

      it "explains that instances cannot be created for a duplicate" do
        subject
        expect(rendered).to include("Cannot create instances for a duplicate name.")
        expect(rendered).not_to have_selector("#instance-form-stub")
      end
    end

    context "and the name is a vernacular name" do
      before { allow(name.name_type).to receive(:vernacular?).and_return(true) }

      it "explains that instances cannot be created for this name type" do
        subject
        expect(rendered).to include("Cannot create instances for a name of this type.")
        expect(rendered).not_to have_selector("#instance-form-stub")
      end
    end
  end

  # A soft deleted name is read only, so the tab is still offered but its form
  # is replaced - see Ability#soft_deleted_name_auth.
  context "when the name has been soft deleted" do
    let(:name) { create(:name, deleted_at: Time.current) }

    it "renders the read-only message" do
      subject
      expect(rendered).to include("This name has been soft-deleted and cannot be modified.")
    end

    it "does not render the add an instance form" do
      subject
      expect(rendered).not_to have_selector("#instance-form-stub")
    end
  end
end
