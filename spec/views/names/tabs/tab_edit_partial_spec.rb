# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_edit.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    # Ability#soft_deleted_name_auth grants :modify to everyone and withdraws
    # it once the name is soft deleted.
    allow(view).to receive(:can?).with(:modify, name) { name.deleted_at.blank? }
    stub_template "names/form/_base.html.erb" => '<div id="name-form-base-stub"></div>'
    stub_template "names/_change_category_widgets.html.erb" => '<div id="change-category-stub"></div>'
    stub_template "names/tabs/_change_category_widgets.html.erb" => '<div id="change-category-stub"></div>'
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_edit" }

  context "when the name has not been soft deleted" do
    it "renders the name form" do
      subject
      expect(rendered).to have_selector("#name-form-base-stub")
    end

    it "renders the change category widgets" do
      subject
      expect(rendered).to have_selector("#change-category-stub")
    end

    it "does not render the read-only message" do
      subject
      expect(rendered).not_to include("This name has been soft-deleted and cannot be modified.")
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

    it "does not render the name form" do
      subject
      expect(rendered).not_to have_selector("#name-form-base-stub")
    end

    it "does not render the change category widgets" do
      subject
      expect(rendered).not_to have_selector("#change-category-stub")
    end
  end
end
