# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instances::SoftDeletesController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ["login"]) }
  let(:name) { FactoryBot.create(:name) }
  let(:instance) { FactoryBot.create(:instance, name:) }

  before do
    emulate_user_login(session_user)
    allow(controller).to receive(:authorise).and_return(true)
  end

  describe "POST #create" do
    context "when soft delete is allowed" do
      before do
        allow_any_instance_of(Instance).to receive(:allow_soft_delete?).and_return(true)
      end

      it "sets deleted_at and renders the success template" do
        post :create, params: {instance_id: instance.id}, format: :js

        expect(instance.reload.deleted_at).to be_present
        expect(response).to render_template("create")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when soft delete is not allowed" do
      before do
        allow_any_instance_of(Instance).to receive(:allow_soft_delete?).and_return(false)
      end

      it "does not set deleted_at and renders the error template" do
        post :create, params: {instance_id: instance.id}, format: :js

        expect(instance.reload.deleted_at).to be_nil
        expect(assigns(:message)).to eq("Soft delete not allowed for this instance.")
        expect(response).to render_template("create_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the instance fails to save" do
      before do
        instance # create the record before the any_instance stubs take effect
        allow_any_instance_of(Instance).to receive(:allow_soft_delete?).and_return(true)
        allow_any_instance_of(Instance).to receive(:save).and_return(false)
        allow_any_instance_of(Instance).to receive(:errors)
          .and_return(instance_double(ActiveModel::Errors, full_messages: ["Save failed"]))
      end

      it "renders the error template with the validation messages" do
        post :create, params: {instance_id: instance.id}, format: :js

        expect(instance.reload.deleted_at).to be_nil
        expect(assigns(:message)).to eq("Save failed")
        expect(response).to render_template("create_error")
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
