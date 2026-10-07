# frozen_string_literal: true

require "rails_helper"

# The change name form's Name field is on stimulus-autocomplete - see
# app/views/shared/_autocomplete_field.html.erb.
RSpec.describe("instances/_form_change_name.html.erb", type: :view) do
  let(:instance) { FactoryBot.create(:instance, draft: true) }

  before do
    assign(:instance, instance)
    allow(view).to(receive(:increment_tab_index).and_return(0))
    allow(view).to(receive(:divider).and_return("<hr>".html_safe))
  end

  it "renders the name field as a stimulus autocomplete" do
    render
    expect(rendered).to(have_selector(
      "form#change-name-form div.autocomplete[data-controller='autocomplete']" \
      "[data-autocomplete-url-value='/instances/#{instance.id}/name/typeahead.html']" \
      " input#instance-name-change-typeahead[name='instance[name_typeahead]']" \
      "[data-autocomplete-target='input'][placeholder='#{instance.name.full_name}']",
    ))
    expect(rendered).not_to(include("setUpInstanceNameChange"))
  end

  it "renders the hidden name id empty, so a name has to be picked" do
    render
    expect(rendered).to(have_selector(
      "div.autocomplete input#instance-change-name-id[name='instance[name_id]']" \
      "[data-autocomplete-target='hidden'][value='']",
      visible: :all,
      count: 1,
    ))
  end
end
