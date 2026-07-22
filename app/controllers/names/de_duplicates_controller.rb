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
#
# Bulk de-duplication of Names.
class Names::DeDuplicatesController < ApplicationController
  before_action :javascript_only, only: %i[transfer_all_dependents]

  def index
  end

  def transfer_all_dependents
    @dependent_type = dependent_params[:dependent_type]
    count = Name.transfer_all_dependents(@dependent_type)
    @message = "#{count} transferred"
    render "names/de_duplicates/transfer_all_dependents/success"
  rescue StandardError => e
    @message = e.to_s.sub("uncaught throw", "").sub(/\A *"/, "").sub(/" *\z/, "")
    render "names/de_duplicates/transfer_all_dependents/error"
  end

  private

  def dependent_params
    params.permit(:id, :dependent_type)
  end
end
