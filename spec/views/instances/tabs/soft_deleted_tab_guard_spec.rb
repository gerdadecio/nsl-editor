# frozen_string_literal: true

require "rails_helper"

# A soft deleted instance is read only - see Ability#soft_deleted_instance_auth.
#
# The tab headings are still offered (see tabs_all_tab_headings_partial_spec.rb);
# refusing the editing content is each tab partial's own job. Every partial
# below is wrapped in a `can?(:modify, @instance)` guard, so with :modify
# withdrawn none of them needs any of its usual collaborators stubbed - the
# guard short circuits before the editing content is reached.
RSpec.describe("the soft delete guard on the instance tab partials", type: :view) do
  let(:instance) { FactoryBot.create(:instance, deleted_at: Time.current) }

  soft_delete_message = "This instance has been soft-deleted and cannot be modified"

  # Tabs that tell the user why the content is missing.
  message_tabs = %w[
    tab_batch_loader
    tab_batch_loader_2
    tab_classification
    tab_comments
    tab_copy_to_new_profile_v2
    tab_copy_to_new_reference
    tab_edit
    tab_edit_notes
    tab_edit_profile
    tab_profile_details
    tab_profile_v2
    tab_synonymy
    tab_synonymy_for_profile_v2
    tab_unpublished_citation
    tab_unpublished_citation_for_profile_v2
  ]

  # Tabs that already had an authorisation fallback and reuse it.
  empty_tabs = %w[tab_edit_profile_v2]

  before do
    assign(:instance, instance)
    allow(view).to(receive(:can?).and_return(true))
    allow(view).to(receive(:can?).with(:modify, instance).and_return(false))
    allow(view).to(receive(:increment_tab_index).and_return(0))
  end

  message_tabs.each do |tab|
    describe "instances/tabs/_#{tab}.html.erb" do
      it "renders the soft deleted message" do
        render(partial: "instances/tabs/#{tab}")
        expect(rendered).to(have_content(soft_delete_message))
      end

      it "renders nothing else" do
        render(partial: "instances/tabs/#{tab}")
        expect(rendered).not_to(have_selector("form"))
        expect(rendered).not_to(have_selector("input[type=submit]"))
      end
    end
  end

  empty_tabs.each do |tab|
    describe "instances/tabs/_#{tab}.html.erb" do
      it "renders the empty tab" do
        render(partial: "instances/tabs/#{tab}")
        expect(rendered).to(render_template(partial: "instances/tabs/_tab_empty"))
      end

      it "renders no editing form" do
        render(partial: "instances/tabs/#{tab}")
        expect(rendered).not_to(have_selector("form"))
      end
    end
  end

  describe "the list of guarded tab partials" do
    it "matches the partials this spec covers" do
      guarded = Dir.glob(Rails.root.join("app/views/instances/tabs/_tab_*.html.erb"))
        .select { |path| File.read(path).include?("can?(:modify, @instance)") }
        .map { |path| File.basename(path).sub(/\A_/, "").sub(/\.html\.erb\z/, "") }

      expect(guarded).to(match_array(message_tabs + empty_tabs))
    end
  end
end
