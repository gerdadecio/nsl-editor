# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Names::SoftDeletesController, type: :controller) do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login"]) }
  let(:name) { FactoryBot.create(:name) }

  before do
    emulate_user_login(session_user)
    allow(controller).to(receive(:authorise).and_return(true))
    allow(Rails.configuration).to(receive(:try).and_call_original)
    allow(Rails.configuration).to(receive(:try).with(:soft_delete_enabled).and_return(true))
  end

  describe "POST #create" do
    let(:allowed_result) do
      double(
        "CheckDeleteResult",
        soft_delete_allowed?: true,
        explanation: "used only in past tree versions",
      )
    end
    let(:blocked_result) do
      double(
        "CheckDeleteResult",
        soft_delete_allowed?: false,
        explanation: "Name is referenced by a live record",
      )
    end

    context "when soft delete is allowed" do
      before do
        allow_any_instance_of(Name).to(receive(:check_delete_result).and_return(allowed_result))
      end

      it "sets deleted_at and renders the success template" do
        post :create, params: { name_id: name.id }, format: :js

        expect(name.reload.deleted_at).to(be_present)
        expect(response).to(render_template("create"))
        expect(response).to(have_http_status(:ok))
      end
    end

    context "when the model validation does not allow the soft delete" do
      before do
        allow_any_instance_of(Name).to(receive(:check_delete_result).and_return(blocked_result))
      end

      it "does not set deleted_at and renders the error template with the reason" do
        post :create, params: { name_id: name.id }, format: :js

        expect(name.reload.deleted_at).to(be_nil)
        expect(assigns(:message)).to(eq("Soft delete not allowed: Name is referenced by a live record"))
        expect(response).to(render_template("create_error"))
        expect(response).to(have_http_status(:unprocessable_content))
      end
    end

    context "when the name fails to save" do
      before do
        name # create the record before the any_instance stubs take effect
        allow_any_instance_of(Name).to(receive(:save).and_return(false))
        allow_any_instance_of(Name).to(receive(:errors)
          .and_return(instance_double(ActiveModel::Errors, full_messages: ["Save failed"])))
      end

      it "renders the error template with the validation messages" do
        post :create, params: { name_id: name.id }, format: :js

        expect(name.reload.deleted_at).to(be_nil)
        expect(assigns(:message)).to(eq("Save failed"))
        expect(response).to(render_template("create_error"))
        expect(response).to(have_http_status(:unprocessable_content))
      end
    end
  end
end
