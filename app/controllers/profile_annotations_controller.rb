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
#
class ProfileAnnotationsController < ApplicationController
  # Similar to ProfileTextsController, ensuring consistency in authorization checks

  def render_add_annotation
    Rails.logger.debug "^^^^^^^^^^^^^$$$$$$$$$$$$$$$$$$$ render_add_annotation ============================"

    profile_item_id = params[:profile_item_id]
    annotation_value = params[:annotation_value] || ""

    render partial: 'instances/tabs/add_annotation', locals: {profile_item_id: profile_item_id, annotation_value: annotation_value}

    # render partial: 'instances/tabs/add_annotation', locals: { instance_id: 'instance_id', display_html: 'display_html', profile_item_id: 'profile_item_id' }
  end

  def create
    # Debugging log to confirm the controller action is hit
    Rails.logger.debug "Profile Annotation Controller Create Action hit."
  
    # Log the full parameters received, including profile_item_id and text_value
    Rails.logger.debug "Received Parameters: #{params.inspect}"
  
    # Extract profile_item_id and text_value from the parameters
    profile_item_id = params[:profile_item_id] rescue nil
    text_value = params[:text_value] rescue nil
  
    # Log the extracted profile_item_id and text_value to ensure they are parsed correctly
    Rails.logger.debug "Parsed profile_item_id: #{profile_item_id}"
    Rails.logger.debug "Parsed text_value: #{text_value}"
  
    # Check for existing ProfileAnnotation based on profile_item_id
    @profile_annotation = Profile::ProfileItemAnnotation.find_by(profile_item_id: profile_item_id)
    if @profile_annotation
      # Update the existing ProfileAnnotation
      Rails.logger.debug "Updating Profile Annotation with profile_item_id: #{profile_item_id}"
      
      # Update the value
      @profile_annotation.value = text_value
      @profile_annotation.updated_by = current_user_id  # Set updated_by to the current user's ID or system user
  
      if @profile_annotation.save
        Rails.logger.debug "+++++++++++++++++++++++ Profile annotation updated successfully. +++++++++++++++++++++"
  
        # Render a JSON response indicating success
        render json: { message: 'Profile annotation updated successfully.', annotation: @profile_annotation, annotation_updated: true, profile_item_id: profile_item_id}, status: :ok
      else
        Rails.logger.error "=========================== Failed to update profile annotation: #{@profile_annotation.errors.full_messages.join(', ')}"
  
        # Render a JSON response indicating failure with error messages
        render json: { errors: @profile_annotation.errors.full_messages, profile_item_id: profile_item_id }, status: :unprocessable_entity
      end
    else
      # Create a new ProfileAnnotation
      Rails.logger.debug "Creating a new Profile Annotation."
  
      # Initialize a new ProfileAnnotation with the extracted parameters
      @profile_annotation = Profile::ProfileItemAnnotation.new(
        profile_item_id: profile_item_id,
        value: text_value,
        created_by: current_user_id, # Set created_by to the current user's ID or system user
        updated_by: current_user_id  # Set updated_by to the current user's ID or system user
      )
  
      # Attempt to save the new ProfileAnnotation
      if @profile_annotation.save
        Rails.logger.debug "+++++++++++++++++++++++ Profile annotation created successfully. +++++++++++++++++++++"
  
        # Render a JSON response indicating success
        render json: { message: 'Profile annotation created successfully.', profile_item_id: profile_item_id, annotation: @profile_annotation, annotation_created: true }, status: :created
      else
        Rails.logger.error "=========================== Failed to create profile annotation: #{@profile_annotation.errors.full_messages.join(', ')}"
  
        # Render a JSON response indicating failure with error messages
        render json: { errors: @profile_annotation.errors.full_messages, profile_item_id: profile_item_id, annotation_error: true}, status: :unprocessable_entity
      end
    end
  end
  


  

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_profile_annotation
    @profile_annotation = Profile::ProfileAnnotation.find(params[:id])
  end

  def current_user_id
    current_user&.id || 'system' # Replace 'system' with a default user identifier if needed
  end

  # Strong parameters for annotation creation
  def annotation_params
    # Directly permit necessary parameters for creating a ProfileAnnotation
    params.permit(:profile_item_id, :text_value)
  end
end
