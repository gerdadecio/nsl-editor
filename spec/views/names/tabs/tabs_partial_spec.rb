# frozen_string_literal: true

require "rails_helper"

RSpec.describe("names/tabs/_tabs.html.erb", type: :view) do
  let(:user) { create(:session_user) }
  let(:current_registered_user) { create(:user) }
  let(:name) { create(:name) }
  let(:product_tab_service_mock) { instance_double(Products::ProductTabService, all_available_tabs: { "name" => [] }) }

  before do
    allow(view).to(receive(:can?).with("instances", "create").and_return(false))
    allow(view).to(receive(:can?).with("names", "update").and_return(false))
    allow(view).to(receive(:can?).with("names", "delete").and_return(false))
    allow(view).to(receive(:can?).with(:create_with_product_reference, Instance).and_return(false))
    allow(view).to(receive(:can?).with(:create, Instance).and_return(true))
    allow(view).to(receive(:can?).with(:manage, Name).and_return(false))
    allow(view).to(receive(:can?).with(:update_common_name, name).and_return(false))
    allow(view).to(receive(:can?).with(:create_common_name, Name).and_return(false))
    allow(view).to(receive(:increment_tab_index).and_return(1))

    mock_service = product_tab_service_mock
    view.define_singleton_method(:product_tab_service) { mock_service }
    assign(:current_user, user)
    assign(:current_registered_user, current_registered_user)
    assign(:tab, "tab_show_1")
    assign(:name, name)

    allow(Rails.configuration).to(receive(:multi_product_tabs_enabled).and_return(false))
  end

  subject { render partial: "names/tabs/tabs" }

  it "renders the Details tab" do
    subject
    expect(rendered).to(have_selector("ul.nav.nav-tabs"))
    expect(rendered).to(have_link("Details", id: "name-details-tab"))
  end

  it "does not render the Edit tab" do
    subject
    expect(rendered).not_to(have_link("Edit", id: "name-edit-tab"))
  end

  it "does not render the Delete tab" do
    subject
    expect(rendered).not_to(have_link("Delete name", id: "name-delete-tab"))
  end

  it "does not render the product-based New instance tab" do
    subject
    expect(rendered).not_to(have_link("New instance", id: "name-instances-profile-v2-tab"))
  end

  it "renders the non-product based New instance tab" do
    subject
    expect(rendered).to(have_link("New instance", id: "name-instances-tab"))
  end

  context "when the user can update names" do
    before do
      allow(view).to(receive(:can?).with("names", "update").and_return(true))
      allow(view).to(receive(:can?).with(:manage, Name).and_return(true))
    end

    it "renders the Edit tab" do
      subject
      expect(rendered).to(have_link("Edit", id: "name-edit-tab"))
    end
  end

  context "when a user can create an instance" do
    before do
      allow(view).to(receive(:can?).with("instances", "create").and_return(true))
    end

    context "and it has :create_with_product_reference to true" do
      before do
        allow(view).to(receive(:can?).with(:create_with_product_reference, Instance).and_return(true))
      end

      it "renders the New instance profile v2 tab" do
        subject
        expect(rendered).to(have_link("New instance", id: "name-instances-profile-v2-tab"))
      end

      it "does not render the regular New instance tab" do
        subject
        expect(rendered).not_to(have_link("New instance", id: "name-instances-tab"))
      end
    end

    context "and it has :create_with_product_reference to false" do
      before do
        allow(view).to(receive(:can?).with(:create_with_product_reference, Instance).and_return(false))
      end

      it "does not render the New instance profile v2 tab" do
        subject
        expect(rendered).not_to(have_link("New instance", id: "name-instances-profile-v2-tab"))
      end

      it "renders the regular New instance tab" do
        subject
        expect(rendered).to(have_link("New instance", id: "name-instances-tab"))
      end
    end
  end

  context "when a user can update a name" do
    before do
      allow(view).to(receive(:can?).with("names", "update").and_return(true))
      allow(view).to(receive(:can?).with(:manage, Name).and_return(true))
    end

    it "renders the Edit tab" do
      subject
      expect(rendered).to(have_link("Edit", id: "name-edit-tab"))
    end
  end

  context "when a user can delete a name" do
    before do
      allow(view).to(receive(:can?).with("names", "delete").and_return(true))
    end

    it "renders the Delete tab" do
      subject
      expect(rendered).to(have_link("Delete name", id: "name-delete-tab"))
    end
  end

  context "More tab visibility" do
    context "when the user can manage Name" do
      before do
        allow(view).to(receive(:can?).with(:manage, Name).and_return(true))
      end

      it "renders the More tab" do
        subject
        expect(rendered).to(have_link("More", id: "name-more-tab"))
      end
    end

    context "when the user can update_common_name on a common name" do
      let(:common_name_type) { instance_double(NameType, name: "common") }
      let(:name) { instance_double(Name, name_type: common_name_type, duplicate?: false, deleted_at: nil) }

      before do
        allow(view).to(receive(:can?).with(:manage, Name).and_return(false))
        allow(view).to(receive(:can?).with(:update_common_name, name).and_return(true))
        assign(:name, name)
      end

      it "renders the More tab" do
        subject
        expect(rendered).to(have_link("More", id: "name-more-tab"))
      end
    end

    context "when the user can update_common_name but the name is not common" do
      before do
        allow(view).to(receive(:can?).with(:manage, Name).and_return(false))
        allow(view).to(receive(:can?).with(:update_common_name, name).and_return(true))
      end

      it "does not render the More tab" do
        subject
        expect(rendered).not_to(have_link("More", id: "name-more-tab"))
      end
    end

    context "when the user has no edit permissions" do
      before do
        allow(view).to(receive(:can?).with(:manage, Name).and_return(false))
        allow(view).to(receive(:can?).with(:update_common_name, name).and_return(false))
      end

      it "does not render the More tab" do
        subject
        expect(rendered).not_to(have_link("More", id: "name-more-tab"))
      end
    end
  end

  describe "editing tabs and the soft delete state of the name" do
    editing_tabs = [
      {
        label: "Edit",
        selector: "a#name-edit-tab",
        permit: proc {
          allow(view).to(receive(:can?).with("names", "update").and_return(true))
          allow(view).to(receive(:can?).with(:manage, Name).and_return(true))
        }
      },
      {
        label: "New instance (product reference)",
        selector: "a#name-instances-profile-v2-tab",
        permit: proc {
          allow(view).to(receive(:can?).with(:create_with_product_reference, Instance).and_return(true))
        }
      },
      {
        label: "New instance",
        selector: "a#name-instances-tab",
        # Loses to the product reference tab when both are permitted.
        superseded_by_product_tab: true,
        permit: proc { allow(view).to(receive(:can?).with(:create, Instance).and_return(true)) }
      },
      {
        label: "Copy",
        selector: "a#name-copy-tab",
        permit: proc { allow(view).to(receive(:can?).with(:create, Instance).and_return(true)) }
      },
      {
        label: "Delete",
        selector: "a#name-delete-tab",
        permit: proc { allow(view).to(receive(:can?).with("names", "delete").and_return(true)) }
      },
      {
        label: "Resource",
        selector: "a#name-resource-tab",
        permit: proc { allow(Rails.configuration).to(receive(:resource_tab_enabled).and_return(true)) }
      },
      {
        label: "More",
        selector: "a#name-more-tab",
        permit: proc { allow(view).to(receive(:can?).with(:manage, Name).and_return(true)) }
      }
    ]

    # The tabs themselves stay visible whatever the soft delete state of the
    # name - each tab partial renders a read-only message in place of its form
    # once :modify is withdrawn. See Ability#soft_deleted_name_auth.
    [
      { state: "has not been soft deleted", deleted_at: nil },
      { state: "has been soft deleted", deleted_at: Time.current }
    ].each do |soft_delete_state|
      context "when the name #{soft_delete_state[:state]}" do
        let(:name) { create(:name, deleted_at: soft_delete_state[:deleted_at]) }

        editing_tabs.each do |editing_tab|
          context "when the user has permission for the '#{editing_tab[:label]}' tab" do
            before { instance_exec(&editing_tab[:permit]) }

            it "renders the '#{editing_tab[:label]}' tab" do
              subject
              expect(rendered).to(have_selector(editing_tab[:selector]))
            end
          end
        end

        context "when the user has every permission" do
          before do
            editing_tabs.each { |editing_tab| instance_exec(&editing_tab[:permit]) }
          end

          it "renders every editing tab" do
            subject
            editing_tabs.reject { |editing_tab| editing_tab[:superseded_by_product_tab] }
                        .each do |editing_tab|
              expect(rendered).to(have_selector(editing_tab[:selector]))
            end
          end

          it "renders the Details tab" do
            subject
            expect(rendered).to(have_selector("a#name-details-tab", text: "Details"))
          end
        end
      end
    end
  end
end
