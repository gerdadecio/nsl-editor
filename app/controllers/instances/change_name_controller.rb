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
  before_action :authorise_instance_change, only: [ :update ]

  def update
    new_name_id = params[:instance]&.fetch(:name_id, nil)

    if new_name_id.blank?
      @message = "Please select a name."
      return render("instances/change_name_error", status: :unprocessable_content)
    end

    if synonym_creation_requested? && (missing = missing_synonym_fields).any?
      @message = "Please enter #{missing.join(" and ")} to add this name as a synonym."
      return render("instances/change_name_error", status: :unprocessable_content)
    end

    service = Instances::ChangeNameService.call(
      instance: @instance,
      new_name_id: new_name_id.to_i,
      username: current_user.username,
      create_synonym: synonym_creation_requested?,
      cites_id: params[:instance][:cites_id],
      synonym_instance_type_id: params[:instance][:synonym_instance_type_id],
    )

    if service.errors.any?
      @message = service.errors.full_messages.join(", ")
      return render("instances/change_name_error", status: :unprocessable_content)
    end

    @message = "Name updated"
    render("instances/change_name")
  rescue => e
    @message = e.to_s
    render("instances/change_name_error", status: :unprocessable_content)
  end

  # Used by the change name form's Name field
  # (app/views/instances/_form_change_name.html.erb).
  #
  # Two formats, as for InstancesController#typeahead_for_synonymy:
  #   html - the fragment of <li role="option"> elements stimulus-autocomplete
  #          expects, which the Name field asks for by extension.
  #   json - what the field asked for while it was on typeahead.js; kept
  #          for parity with the other suggestion actions, nothing in this
  #          app's own views still asks for it. Also the answer to any other
  #          format, as it was before html was added.
  def typeahead
    typeahead = Instance::AsTypeahead::ForChangeName.new(
      term: params[:term],
      name_type_id: @instance.name.name_type_id,
      name_rank_id: @instance.name.name_rank_id,
      exclude_name_id: @instance.name_id,
    )
    respond_to do |format|
      format.json { render json: typeahead.suggestions }
      format.html do
        render partial: "shared/autocomplete_suggestions",
               locals: { suggestions: typeahead.suggestions, term: params[:term] }
      end
      format.any { render json: typeahead.suggestions }
    end
  end

  private

  def synonym_creation_requested?
    params[:instance]&.fetch(:create_synonym, nil) == "yes"
  end

  def missing_synonym_fields
    fields = []
    fields << "an instance (the name and optional year)" if params[:instance][:cites_id].blank?
    fields << "a type" if params[:instance][:synonym_instance_type_id].blank?
    fields
  end

  # A soft deleted instance is read only -
  # see Ability#soft_deleted_instance_auth.
  def authorise_instance_change
    authorize!(:modify, @instance)
  end

  def find_instance
    @instance = Instance.find(params[:instance_id])
  end
end
