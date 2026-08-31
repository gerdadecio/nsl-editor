# frozen_string_literal: true

require "rails_helper"

RSpec.describe "names/tabs/_tab_delete.html.erb", type: :view do
  let(:name) { create(:name) }

  before do
    # Ability#soft_deleted_name_auth grants :modify to everyone and withdraws
    # it once the name is soft deleted.
    allow(view).to receive(:can?).with(:modify, name) { name.deleted_at.blank? }
    allow(view).to receive(:increment_tab_index).and_return(1)
    stub_template "names/widgets/_delete_widgets.html.erb" => '<div id="delete-widgets-stub"></div>'
    stub_template "names/widgets/_soft_delete_widgets.html.erb" => '<div id="soft-delete-widgets-stub"></div>'
    stub_template "names/widgets/_cannot_delete_info.html.erb" => '<div id="cannot-delete-info-stub"></div>'
    stub_template "names/widgets/_delete_dependents_summary.html.erb" => '<div id="dependents-summary-stub"></div>'
    assign(:name, name)
  end

  subject { render partial: "names/tabs/tab_delete" }

  context "when the name has not been soft deleted" do
    context "and a hard delete is allowed" do
      before { allow(name).to receive(:allow_delete?).and_return(true) }

      it "renders the delete widgets" do
        subject
        expect(rendered).to have_selector("#delete-widgets-stub")
      end
    end

    context "and only a soft delete is allowed" do
      before do
        allow(name).to receive(:allow_delete?).and_return(false)
        allow(name).to receive(:allow_soft_delete?).and_return(true)
      end

      it "renders the soft delete widgets" do
        subject
        expect(rendered).to have_selector("#soft-delete-widgets-stub")
      end
    end

    context "and no delete is allowed" do
      before do
        allow(name).to receive(:allow_delete?).and_return(false)
        allow(name).to receive(:allow_soft_delete?).and_return(false)
      end

      it "renders the cannot delete information" do
        subject
        expect(rendered).to have_selector("#cannot-delete-info-stub")
      end
    end

    it "renders the delete dependents summary" do
      subject
      expect(rendered).to have_selector("#dependents-summary-stub")
    end
  end

  # A soft deleted name is read only, so the tab is still offered but its
  # widgets are replaced - see Ability#soft_deleted_name_auth.
  context "when the name has been soft deleted" do
    let(:name) { create(:name, deleted_at: Time.current) }

    before do
      allow(name).to receive(:allow_delete?).and_return(false)
      allow(name).to receive(:allow_soft_delete?).and_return(true)
    end

    it "renders the read-only message" do
      subject
      expect(rendered).to include("This name has been soft-deleted and cannot be modified.")
    end

    it "renders none of the delete widgets" do
      subject
      expect(rendered).not_to have_selector("#delete-widgets-stub")
      expect(rendered).not_to have_selector("#soft-delete-widgets-stub")
      expect(rendered).not_to have_selector("#cannot-delete-info-stub")
    end

    it "does not render the delete dependents summary" do
      subject
      expect(rendered).not_to have_selector("#dependents-summary-stub")
    end
  end
end
