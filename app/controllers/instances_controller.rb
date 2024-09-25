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

#   Controls instances.
class InstancesController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_action :find_instance, only: %i[show tab destroy]
  # TODO: refactor validation error checks to not rely on a copied string comparison as this is very fragile
  CONCEPT_WARNING = "Validation failed: You are trying to change an accepted concept's synonymy."

  # GET /instances/1
  # GET /instances/1/tab/:tab
  # Sets up RHS details panel on the search results page.
  # Displays a specified or default tab.
  def show
        @tab = tab_or_default_tab
    @tab_index = (params[:tabIndex] || "1").to_i
    @tabs_to_offer = tabs_to_offer
    @row_type = params["row-type"]
    # Really only need to do this if the "classification" tab is chosen.
    unless @working_draft.blank?
      @tree_version_element = @working_draft.name_in_version(@instance.name)
      @parent_tve = find_a_parent(@instance.name)
    end
    @accepted_tve = @instance.name.accepted_tree_version_element
    @take_focus = params[:take_focus] == "true"
    render "show", layout: false
  end

  alias tab show

  # Create the lesser version of relationship instance.
  def create_cited_by
    logger.debug("create_cited_by")
    resolve_unpub_citation_name_id(instance_params[:name_id],
                                   instance_name_params[:name_typeahead])
    if instance_params[:name_id].blank?
      render_create_error("You must choose a name.", "instance-name-typeahead")
    elsif instance_params[:instance_type_id].blank?
      render_create_error("You must choose an instance type.",
                          "instance_instance_type_id")
    else
      create(instance_params, "create_unpub")
    end
  rescue StandardError => e
    render_create_error(e.to_s, "instance-name-typeahead")
  end

  # Create full synonymy instance.
  def create_cites_and_cited_by
    logger.debug("create_cites_and_cited_by")
    if instance_params[:cites_id].blank?
      render_cites_id_error
    elsif instance_params[:cited_by_id].blank?
      render_cited_by_id_error
    elsif instance_params[:instance_type_id].blank?
      render_instance_type_id_error
    else
      create(build_the_params, "create")
    end
  end

  # Core create action.
  # Sometimes we need to massage the params (safely) before calling this create.
  def create(the_params = instance_params, view_to_render = "create")
    @instance = Instance.new(the_params)
    check_for_overrides
    @instance.save_with_username(current_user.username)
    render view_to_render
  rescue ActiveRecord::RecordNotUnique
    handle_not_unique
  rescue StandardError => e
    handle_other_errors(e)
  end

  def check_for_overrides
    @instance.concept_warning_bypassed =
      instance_params[:concept_warning_bypassed] == "1"
    @instance.multiple_primary_override =
      instance_params[:multiple_primary_override] == "1"
    @instance.duplicate_instance_override =
      instance_params[:duplicate_instance_override] == "1"
    prevent_double_overrides
  end
  private :check_for_overrides

  def prevent_double_overrides
    if @instance.multiple_primary_override &&
       @instance.duplicate_instance_override
      @instance.multiple_primary_override = false
      @instance.duplicate_instance_override = false
    end
  end
  private :prevent_double_overrides

  # Copy an instance with its citations
  def copy_standalone
    logger.debug("================================= copy_standalone ===========================================")
    # current_instance = Instance::AsCopier.find(params[:id])
    # current_instance.multiple_primary_override =
    #   instance_params[:multiple_primary_override] == "1"
    # current_instance.duplicate_instance_override =
    #   instance_params[:duplicate_instance_override] == "1"
    # @instance = current_instance.copy_with_citations_to_new_reference(
    #   instance_params, current_user.username
    # )
    # @message = "Instance was copied"
    # render "instances/copy_standalone/success"
  rescue StandardError => e
    handle_other_errors(e, "instances/copy_standalone/error")
  end

  def handle_not_unique
    @message = "Error: duplicate record"
    render "create_error", status: :unprocessable_entity
  end
  private :handle_not_unique

  def handle_other_errors(e, file_to_render = "create_error")
    logger.debug("handle_other_errors")
    logger.error(e.to_s)
    errors = ErrorAsArrayOfMessages.new(e).error_array
    if errors.size <= 1
      @allow_bypass = errors.first.match(/\A#{CONCEPT_WARNING}\z/)
      @multiple_primary_override = errors.first.match(/#{Instance::MULTIPLE_PRIMARY_WARNING}\z/) ? true : false
      @duplicate_instance_override = errors.first.match(/#{Instance::DUPLICATE_INSTANCE_WARNING}\z/) ? true : false
    end
    @message = errors
    render file_to_render, status: :unprocessable_entity
  end
  private :handle_other_errors

  # PUT /instances/1
  # PUT /instances/1.json
  def update
    @instance = Instance::AsEdited.find(params[:id])
    @message = @instance.update_if_changed(instance_params,
                                           current_user.username)
    render "update"
  rescue StandardError => e
    handle_other_errors(e, "update_error")
  end

  # PUT /instances/reference/1
  # PUT /instances/reference/1.json
  # Changing the reference for an instance is a special case -
  # there may/will exist denormalised ids in dependent instances.
  # We have to temporarily bypass some validations to sort it out.
  def change_reference
    @message = "No change"
    @instance = Instance.find(params[:id])
    @instance.assign_attributes(instance_params)
    make_back_door_changes if @instance.changed?
    render "update"
  rescue StandardError => e
    logger.error(e.to_s)
    @message = e.to_s
    render "update_error", status: :unprocessable_entity
  end

  def make_back_door_changes
    @instance_back_door = InstanceBackDoor.find(params[:id])
    @instance_back_door.change_reference(instance_params,
                                         current_user.username)
    @message = "Updated"
  end

  # DELETE /instances/1
  def destroy
    @instance.delete_as_user(current_user.username)
  rescue StandardError => e
    logger.error("Instance#destroy exception: #{e}")
    @message = e.to_s
    render "destroy_error", status: 422
  end

  def typeahead_for_synonymy
    instances = Instance::AsTypeahead::ForSynonymy.new(params[:term],
                                                       params[:name_id])
    render json: instances.results
  end

  # Expect instance id - of the instance user is updating.
  # Synonym Edit tab.
  def typeahead_for_name_showing_references_to_update_instance
    typeahead = Instance::AsTypeahead::ForNameShowingReferences.new(params)
    render json: typeahead.references
  end

  private

  def find_instance
    @instance = Instance.find(params[:id])
    # get all the display_html from the profile_product table, it is what a user can do
    if Rails.configuration.try('foa_profile_aware')
      sql_get_all_display_html = <<-SQL
      SELECT 
        pp.display_html as display_html, 
        pot.name as pot_name,
        p.id as product_id,
        pp.id as profile_product_id,
        pit.id as profile_item_type_id, 
        pot.id as profile_object_type_id
      FROM temp_profile.product p
      JOIN temp_profile.profile_product pp on p.id = pp.product_id
      JOIN temp_profile.profile_item_type pit on pp.profile_item_type_id = pit.id
      JOIN temp_profile.profile_object_type pot on pit.profile_object_type_id = pot.id
      ORDER BY pp.sort_order;
      SQL

      foas_all = ActiveRecord::Base.connection.execute(sql_get_all_display_html)
      # Initialize the hash to store the data
      data_hash_foas_all = {}

      foas_all.each do |row|
        data_hash_foas_all[row['display_html']] = {
        "pot_name" => row['pot_name'],
        "product_id" => row['product_id'],
        "profile_product_id" => row['profile_product_id'],
        "profile_item_type_id" => row['profile_item_type_id'],
        "profile_object_type_id" => row['profile_object_type_id']
      }
      end

      instance_id = params[:id]  
      sql_get_existent_display_html_by_instance_id = ActiveRecord::Base.sanitize_sql_array([<<-SQL, instance_id])
        SELECT pp.display_html AS display_html,
              pi.id AS profile_item_id,
              ptx.id AS profile_text_id,
              pit.id AS profile_item_type_id,
              pp.id AS profile_product_id,
              ptx.value AS text_value,
              pan.value as annotation_value,
              pan.id as profile_annotation_id,
              pref.reference_id as reference_id,
			        pref.annotation as reference_annotation
        FROM temp_profile.profile_item pi
        JOIN temp_profile.profile_text ptx ON pi.profile_text_id = ptx.id
        JOIN temp_profile.profile_item_type pit ON pi.profile_item_type_id = pit.id
        JOIN temp_profile.profile_product pp ON pit.id = pp.profile_item_type_id
        LEFT JOIN temp_profile.profile_annotation pan ON pan.profile_item_id = pi.id
        LEFT JOIN temp_profile.profile_reference pref ON pref.profile_item_id =pi.id
        WHERE pi.instance_id = ?;
      SQL
      
      foas_existent = ActiveRecord::Base.connection.execute(sql_get_existent_display_html_by_instance_id)

      data_hash_existent_foas = {}
      foas_existent.each do |row|
        data_hash_existent_foas[row['display_html']] = {
          "profile_item_id" => row['profile_item_id'],
          "profile_text_id" => row['profile_text_id'],
          "profile_item_type_id" => row['profile_item_type_id'],
          "profile_product_id" => row['profile_product_id'],
          "text_value" => row['text_value'],
          "annotation_value" => row['annotation_value'],
          "profile_annotation_id" => row['profile_annotation_id'],
          "reference_id" => row['reference_id'],
          "reference_annotation" => row['reference_annotation']
        }
      end


      Rails.logger.debug " =================== Data Hash Existent FOAs: #{data_hash_existent_foas.inspect}=================="


      @data_hash_foas_all = data_hash_foas_all
      @data_hash_existent_foas = data_hash_existent_foas
      @instance_id = instance_id
    end

  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "We could not find the instance."
    redirect_to instances_path
  end
  

  def instance_params
    params.require(:instance).permit(:instance_type,
                                     :name_id,
                                     :reference_id,
                                     :instance_type_id,
                                     :verbatim_name_string,
                                     :page,
                                     :cites_id,
                                     :cited_by_id,
                                     :bhl_url,
                                     :concept_warning_bypassed,
                                     :multiple_primary_override,
                                     :duplicate_instance_override,
                                     :draft,
                                     :parent_id,
                                     :instance_id)
  end

  def instance_name_params
    params.require(:instance).permit(:name_id, :name_typeahead)
  end

  def tab_or_default_tab
    if params[:tab] && !params[:tab].blank? && params[:tab] != "undefined"
      params[:tab]
    else
      "tab_show_1"
    end
  end

  # Different types of instances require different sets of tabs.
  def tabs_to_offer
    offer = %w[tab_show_1 tab_edit tab_edit_notes]
    if @instance.standalone?
      offer << "tab_synonymy"
      offer << "tab_unpublished_citation"
      offer << "tab_classification"
      offer << "tab_profile_details" if @instance.profile?
      offer << "tab_edit_profile" if @instance.profile? && @instance.show_apc?
      offer << "tab_foa_profile"
    end
    offer << "tab_comments"
    offer << "tab_copy_to_new_reference" if offer_tab_copy_to_new_ref?
    if Rails.configuration.try('batch_loader_aware') &&
          can?('loader/names', 'update') &&
          offer_loader_tab?
        offer << "tab_batch_loader" 
        offer << "tab_batch_loader_2" 
    end
    offer
  end

  def offer_tab_copy_to_new_ref?
    @instance.standalone? &&
      params["row-type"] == "instance_as_part_of_concept_record"
  end

  def offer_loader_tab?
    return true if @instance.standalone? &&
      params["row-type"] == "instance_as_part_of_concept_record"
    return true if @instance.relationship? &&
      params["row-type"] == "instance_is_cited_by" && !@instance.unsourced?

    false
  end

  def render_create_error(base_error_string, focus_id)
    @instance = Instance.new
    @instance.errors.add(:base, base_error_string)
    @message = base_error_string
    render "create_error", locals: { focus_on_this_id: focus_id }
  end

  def render_cites_id_error
    render_create_error(
      "You must choose an instance.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_cited_by_id_error
    render_create_error(
      "Please refresh the tab.",
      "instance-instance-for-name-showing-reference-typeahead"
    )
  end

  def render_instance_type_id_error
    render_create_error(
      "You must choose an instance type.",
      "instance_instance_type_id"
    )
  end

  def cites_and_cited_by
    [Instance.find(instance_params[:cites_id]),
     Instance.find(instance_params[:cited_by_id])]
  end

  def build_the_params
    cites, cited_by = cites_and_cited_by
    build_them(cites, cited_by)
  end

  def build_them(cites, cited_by)
    { name_id: cites.name.id,
      cites_id: cites.id,
      cited_by_id: cited_by.id,
      reference_id: cited_by.reference.id,
      instance_type_id: instance_params[:instance_type_id],
      verbatim_name_string: instance_params[:verbatim_name_string],
      bhl_url: instance_params[:bhl_url],
      draft: instance_params[:draft],
      page: instance_params[:page] }
  end

  def resolve_unpub_citation_name_id(name_id, name_typeahead)
    return unless instance_params[:name_id].blank?

    params[:instance][:name_id] = Name::AsResolvedTypeahead::ForUnpubCitationInstance.new(name_id, name_typeahead).value
  end

  def find_a_parent(parent)
    while parent
      parent_tve = @working_draft.name_in_version(parent)
      return parent_tve if parent_tve

      parent = parent.parent
    end
    @working_draft.tree_version_elements.order(tree_element_id: "asc").first
  end
end
