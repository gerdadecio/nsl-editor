require 'rails_helper'

RSpec.describe ProfileItems::LinksController, type: :controller do
  let(:session_user) { FactoryBot.create(:session_user, groups: ['login']) }
  let(:current_user) { FactoryBot.create(:user) }

  before do
    emulate_user_login(session_user, current_user)
    allow(controller).to receive(:can?).and_return("profile_items", :all)
  end

  describe "POST #create" do
    let(:instance) { instance_double("Instance", id: 1) }
    let(:source_profile_item) { instance_double("Profile::ProfileItem", id: 1, profile_text_id: 1, product_item_config_id: 1, fact?: true) }
    let(:service_errors) { ActiveModel::Errors.new("Some error") }
    let(:profile_item) { instance_double("Profile::ProfileItem", id: 2) }
    let(:mock_service_result) { double("ProfileItems::Links::CreateService", profile_item: profile_item, errors: {}) }
    let(:params) { { instance_id: instance.id, id: source_profile_item.id } }

    subject { post :create, params: params}

    before do
      allow(Instance).to receive(:find).with(params[:instance_id].to_s).and_return(instance)
      allow(Profile::ProfileItem).to receive(:find).with(source_profile_item.id.to_s).and_return(source_profile_item)
    end

    context "when the service succeeds" do
      before do
        allow(mock_service_result.errors).to receive(:any?).and_return(false)
        allow(ProfileItems::Links::CreateService).to receive(:call).and_return(mock_service_result)
      end

      it "calls the CreateService with the correct parameters" do
        subject
        expect(ProfileItems::Links::CreateService).to have_received(:call)
      end

      it "assigns the created profile item to @profile_item" do
        subject
        expect(assigns(:profile_item)).to eq(profile_item)
      end

      it "does not render the 'create_failed' template" do
        subject
        expect(response).not_to render_template("create_failed")
      end
    end

    context "when the service fails" do
      let(:service_errors) do
        errors = ActiveModel::Errors.new(ProfileItems::Links::CreateService.new(instance: instance, user: current_user, source_profile_item: source_profile_item, params: params))
        errors.add(:base, "An error occurred")
        errors
      end
      let(:mock_service_result) { double("ProfileItems::Links::CreateService", profile_item: profile_item, errors: service_errors) }

      before do
        allow(ProfileItems::Links::CreateService).to receive(:call).and_return(mock_service_result)
        allow(mock_service_result.errors).to receive(:any?).and_return(true)
      end

      subject { post :create, params: params, format: :turbo_stream }

      it "assigns the error message to @message" do
        subject
        expect(assigns(:message)).to eq("Error deleting profile item: An error occurred")
      end

      it "renders the 'create_failed' template" do
        subject
        expect(response).to render_template("create_failed")
      end
    end
  end

  describe "PUT #update" do
    let(:instance) { instance_double("Instance", id: 1) }
    let(:profile_text) { instance_double("ProfileText", id: 1) }
    let(:source_profile_item) { instance_double("Profile::ProfileItem", id: 1, product_item_config_id: 1, fact?: true) }
    let(:new_profile_item) { instance_double("Profile::ProfileItem", id: 2, profile_text: profile_text, product_item_config_id: 1, instance: instance) }
    let(:params) { { id: source_profile_item.id } }

    subject { put :update, params: params, format: :turbo_stream }

    before do
      allow(ProfileItems::Links::UpdateService).to receive(:call).and_return(service_result)
      allow(Profile::ProfileItem).to receive(:find).and_return(source_profile_item)
    end

    context 'when the update is successful' do
      let(:service_result) do
        double(
          errors: [],
          profile_item: new_profile_item,
          profile_text: profile_text
        )
      end

      before do
        allow(ProfileItems::Links::UpdateService).to receive(:call).and_return(service_result)
        allow(Profile::ProfileItem::DefinedQuery::ProductAndProductItemConfigs).to receive_message_chain(:new, :run_query).and_return([])
      end

      it 'assigns the updated profile item and renders the index template' do
        subject
        expect(assigns(:profile_item)).to eq(new_profile_item)
        expect(assigns(:profile_text)).to eq(profile_text)
        expect(assigns(:instance)).to eq(instance)
        expect(response).to render_template("profile_items/index")
      end
    end

    context 'when the update fails' do
      let(:service_result) do
        double(
          errors: double(full_messages: ["An error occurred"], any?: true),
          profile_item: nil,
          profile_text: nil
        )
      end

      it 'assigns an error message and renders the update_failed template' do
        subject
        expect(assigns(:message)).to eq("Error deleting profile item: An error occurred")
        expect(response).to render_template("update_failed")
      end
    end
  end
end
