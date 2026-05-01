# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

class Instances::ChangeNameController < ApplicationController
  before_action :find_instance

  def update
    new_name_id = params[:instance]&.fetch(:name_id, nil)
    if new_name_id.blank?
      @message = "Please select a name."
      return render("instances/change_name_error", status: :unprocessable_content)
    end
    service = Instances::ChangeNameService.call(
      instance: @instance,
      new_name_id: new_name_id.to_i,
      username: current_user.username
    )
    if service.errors.any?
      @message = service.errors.full_messages.join(", ")
      return render("instances/change_name_error", status: :unprocessable_content)
    end
    @message = "Name updated"
    render("instances/change_name")
  rescue StandardError => e
    @message = e.to_s
    render("instances/change_name_error", status: :unprocessable_content)
  end

  def typeahead
    typeahead = Instance::AsTypeahead::ForChangeName.new(
      term: params[:term],
      name_type_id: @instance.name.name_type_id,
      name_rank_id: @instance.name.name_rank_id,
      exclude_name_id: @instance.name_id,
    )
    render(json: typeahead.suggestions)
  end

  private

  def find_instance
    @instance = Instance.find(params[:instance_id])
  end
end
