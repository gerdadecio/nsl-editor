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

class Names::SoftDeletesController < ApplicationController
  before_action :find_name, only: [:create]

  def create
    # set name as soft-deleted
    if @name.allow_soft_delete?
      @name.current_user = current_user
      @name.deleted_at = Time.current
      unless @name.save
        @message = @name.errors.full_messages.join("; ")
        return render "create_error", status: :unprocessable_content
      end
    else
      @message = "Soft delete not allowed for this name."
      return render "create_error", status: :unprocessable_content
    end
  end

  private

  def find_name
    @name = Name.find(params[:id])
  end
end
