module ProfileItems
  class VersionedCopiesController < ProfileItemsController

    before_action :set_profile_item
    before_action :authorise_user!, only: [:create]

    def create
      @instance = Instance.find(params[:instance_id])
      result = ProfileItems::Published::CreateNewVersionService.call(
        instance: @instance,
        profile_item: @profile_item,
        user: current_registered_user,
        params: params
      )
      @new_profile_item = result.new_profile_item

      if result.errors.any?
        @message = "Error creating versioned copy of a profile item: #{result.errors.full_messages.to_sentence}"
        render "create_failed"
      else
        @message = "Versioned copy created successfully."
      end
    end

    private

    def authorise_user!
      raise CanCan::AccessDenied.new("Access Denied!", :manage, @profile_item) unless can? :create_version, @profile_item
    end
  end
end
