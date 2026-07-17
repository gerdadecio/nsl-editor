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

class Instances::SoftDeletesController < ApplicationController
  before_action :find_instance

  def create
    # set instance as soft-deleted
    if @instance.allow_soft_delete?
      @instance.current_user = current_user
      @instance.deleted_at = Time.current
      unless @instance.save
        @message = @instance.errors.full_messages.join("; ")
        return render "create_error", status: :unprocessable_content
      end
    else
      @message = "Soft delete not allowed for this instance."
      return render "create_error", status: :unprocessable_content
    end
  end

  private

  def find_instance
    @instance = Instance.find(params[:instance_id])
  end
end
