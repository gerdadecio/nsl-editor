# frozen_string_literal: true

require "rails_helper"

RSpec.describe Names::SoftDeletesController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login"]) }
  let(:name) { FactoryBot.create(:name) }

  before do
    emulate_user_login(session_user)
    allow(controller).to receive(:authorise).and_return(true)
  end

  describe "POST #create" do
    context "when soft delete is allowed" do
      before do
        allow_any_instance_of(Name).to receive(:allow_soft_delete?).and_return(true)
      end

      it "sets deleted_at and renders the success template" do
        post :create, params: {name_id: name.id}, format: :js

        expect(name.reload.deleted_at).to be_present
        expect(response).to render_template("create")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when soft delete is not allowed" do
      before do
        allow_any_instance_of(Name).to receive(:allow_soft_delete?).and_return(false)
      end

      it "does not set deleted_at and renders the error template" do
        post :create, params: {name_id: name.id}, format: :js

        expect(name.reload.deleted_at).to be_nil
        expect(assigns(:message)).to eq("Soft delete not allowed for this name.")
        expect(response).to render_template("create_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the name fails to save" do
      before do
        name # create the record before the any_instance stubs take effect
        allow_any_instance_of(Name).to receive(:allow_soft_delete?).and_return(true)
        allow_any_instance_of(Name).to receive(:save).and_return(false)
        allow_any_instance_of(Name).to receive(:errors)
          .and_return(instance_double(ActiveModel::Errors, full_messages: ["Save failed"]))
      end

      it "renders the error template with the validation messages" do
        post :create, params: {name_id: name.id}, format: :js

        expect(name.reload.deleted_at).to be_nil
        expect(assigns(:message)).to eq("Save failed")
        expect(response).to render_template("create_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
