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

# Help display audit information.
module AuditHelper
  def created_by_whom_and_when(record)
    %(Created <span class="purple"
    >#{time_ago_in_words(record.created_at)}&nbsp;ago</span>
    by #{record.created_by} #{formatted_timestamp(record.created_at)})
  end

  def quoted_original_content_created_by_whom_and_when(record)
    %(created <span class="purple"
    >#{time_ago_in_words(record.created_at)}&nbsp;ago</span>
    by #{record.created_by} #{formatted_timestamp(record.created_at)})
  end

  def quoted_original_content_updated_by_whom_and_when(record)
    %(updated <span class="purple"
    >#{time_ago_in_words(record.updated_at)}&nbsp;ago</span>
    by #{record.updated_by} #{formatted_timestamp(record.updated_at)})
  end

  # Only show updated_at if a meaningful time after created_at.
  def updated_by_whom_and_when(record)
    if record_updated?(record)
      meaningful_update(record)
    else
      "Not updated since it was created."
    end
  end

  def meaningful_update(record)
    %(Last updated
    <span class="purple">#{time_ago_in_words(record.updated_at)}&nbsp;ago
    </span> by #{record.updated_by} #{formatted_timestamp(
      record.updated_at
    )})
  end

  def meaningful_update_when_no_created_at(record)
    %(Created or last updated
    <span class="purple">#{time_ago_in_words(record.updated_at)}&nbsp;ago
    </span> by #{record.updated_by} #{formatted_timestamp(
      record.updated_at
    )})
  end

  def profile_item_created_audit(profile_item)
    record = profile_item.profile_text
    if profile_item.fact?
      "#{created_by_whom_and_when(record)} as original content"
    else
      quoted_original_content_created_by_whom_and_when(record)
    end
  end

  def profile_item_updated_audit(profile_item)
    record = profile_item.profile_text
    return quoted_original_content_updated_by_whom_and_when(record) unless profile_item.fact?

    if record_updated?(record)
      "#{meaningful_update(record)} as original content"
    else
      "Not updated since it was created."
    end
  end

  def published_by_whom_and_when(record)
    published = published_timestamp(record)
    return "" if published.nil?

    %(Published <span class="purple"
    >#{time_ago_in_words(published)}&nbsp;ago</span>
    by #{published_author(record)} #{formatted_timestamp(published)})
  end

  private

  def record_updated?(record)
    (record.created_at.to_f / 10).to_i != (record.updated_at.to_f / 10).to_i
  end

  def published_timestamp(record)
    if record.respond_to?(:published_at) && record.published_at
      record.published_at
    elsif record.respond_to?(:published_date) && record.published_date
      record.published_date
    end
  end

  def published_author(record)
    if record.respond_to?(:published_by) && record.published_by
      record.published_by
    else
      record.updated_by
    end
  end
end
