# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_resource.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    # Ability#soft_deleted_name_auth grants :modify to everyone and withdraws
    # it once the name is soft deleted.
    allow(view).to receive(:can?).with(:modify, name) { name.deleted_at.blank? }
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "names/name_resources/_list.html.erb" => '<div class="name-resource-stub"></div>'
    stub_template "names/name_resources/_resource_host_dropdown_form.html.erb" =>
      '<div id="resource-host-dropdown-stub"></div>'
    stub_template "names/name_resources/_add_resource_form.html.erb" => '<div id="add-resource-form-stub"></div>'
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_resource" }

  context "when the name has not been soft deleted" do
    it "renders the Name Resource heading and list container" do
      subject
      expect(rendered).to have_selector("h5", text: "Name Resource")
      expect(rendered).to have_selector("#name-resource-list-container")
    end

    it "renders the add resource forms" do
      subject
      expect(rendered).to have_selector("#resource-host-dropdown-stub")
      expect(rendered).to have_selector("#add-resource-form-stub")
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

    it "does not render the add resource forms" do
      subject
      expect(rendered).not_to have_selector("#resource-host-dropdown-stub")
      expect(rendered).not_to have_selector("#add-resource-form-stub")
    end

    it "does not render the resource list container" do
      subject
      expect(rendered).not_to have_selector("#name-resource-list-container")
    end
  end
end
