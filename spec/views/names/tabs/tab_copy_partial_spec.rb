# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_copy.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    # Ability#soft_deleted_name_auth grants :modify to everyone and withdraws
    # it once the name is soft deleted.
    allow(view).to receive(:can?).with(:modify, name) { name.deleted_at.blank? }
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "names/form/_copy.html.erb" => '<div id="copy-form-stub"></div>'
    stub_template "names/form/_copy_instances.html.erb" => '<div id="copy-instances-form-stub"></div>'
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_copy" }

  context "when the name has not been soft deleted" do
    it "renders the Copy Name heading and form" do
      subject
      expect(rendered).to have_selector("h5", text: "Copy Name")
      expect(rendered).to have_selector("#copy-form-stub")
    end

    it "renders the Copy Standalone Instances section" do
      subject
      expect(rendered).to have_selector("h5", text: "Copy Standalone Instances")
    end

    context "and the name is a duplicate" do
      before { allow(name).to receive(:duplicate?).and_return(true) }

      it "explains that a duplicate cannot be copied" do
        subject
        expect(rendered).to include("Cannot copy a record that is marked as a duplicate.")
        expect(rendered).not_to have_selector("#copy-form-stub")
      end
    end

    context "and the name has no standalone instances" do
      it "says there is nothing to copy" do
        subject
        expect(rendered).to include("No instances available to copy.")
        expect(rendered).not_to have_selector("#copy-instances-form-stub")
      end
    end
  end

  # A soft deleted name is read only, so the tab is still offered but its
  # forms are replaced - see Ability#soft_deleted_name_auth.
  context "when the name has been soft deleted" do
    let(:name) { create(:name, deleted_at: Time.current) }

    it "renders the read-only message" do
      subject
      expect(rendered).to include("This name has been soft-deleted and cannot be modified.")
    end

    it "does not render the copy name form" do
      subject
      expect(rendered).not_to have_selector("#copy-form-stub")
    end

    it "does not render the copy standalone instances section" do
      subject
      expect(rendered).not_to have_selector("h5", text: "Copy Standalone Instances")
    end
  end
end
