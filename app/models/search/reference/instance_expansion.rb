# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# Expands the references a search matched with their instances
# (show-instances:) or novelties (show-novelties:), for
# Search::OnModel::Base and Search::Reference::DefinedQuery.
#
# NSL-6001: each reference shows at most instance-limit: standalone
# instances (default 1000), starting after instance-offset:. The limit is
# applied in SQL (see Instance::AsArray::ForReference::Windowable), and
# where a reference has more, or some were skipped, a notice row follows
# its instances saying which ones are shown, with a link to the next lot.
#
# results interleaves each reference with its instance rows and any
# notice. instance_row_count counts the instance rows, including the
# synonymy shown beneath each standalone, but not references or notices.
class Search::Reference::InstanceExpansion
  NOTICE = "instances-limited-notice"

  attr_reader :results, :instance_row_count

  # records is normally just References. Anything else (rows from an
  # earlier expansion, when show-instances: and show-novelties: are
  # combined) passes through unchanged.
  def initialize(records, parsed_request, novelties: false)
    @records = records.to_a
    @references = @records.grep(Reference)
    @parsed_request = parsed_request
    @novelties = novelties
    @offset = parsed_request.instance_offset || 0
    @limit = parsed_request.instance_limit || Search::ParsedRequest::DEFAULT_INSTANCE_LIMIT
    @results = []
    @instance_row_count = 0
    expand
  end

  private

  def expand
    preloaded, cited_by_map = preload
    totals = expander.standalone_counts_for(@references.map(&:id))
    @records.each do |ref|
      @results << ref
      next unless ref.is_a?(Reference)

      rows = instances_for(ref, preloaded[ref.id] || [], cited_by_map)
      @results.concat(rows)
      @instance_row_count += rows.size
      consider_notice(ref, totals[ref.id] || 0, rows.size)
    end
  end

  def expander
    if @novelties
      Instance::AsArray::ForReference::ForNovelties
    else
      Instance::AsArray::ForReference
    end
  end

  def preload
    if @novelties
      [ expander.preload_for(@references, sort_by: sort_key, offset: @offset, limit: @limit), nil ]
    else
      expander.preload_for(@references, sort_by: sort_key, offset: @offset, limit: @limit)
    end
  end

  # Offset and limit were applied by preload, so none here.
  def instances_for(ref, preloaded_instances, cited_by_map)
    if @novelties
      expander.new(ref, sort_key, nil, 0, preloaded_instances: preloaded_instances).results
    else
      expander.new(ref, sort_key, nil, 0,
                   preloaded_instances: preloaded_instances,
                   preloaded_cited_by_map: cited_by_map).results
    end
  end

  def by_page?
    @novelties ? @parsed_request.order_novelties_by_page : @parsed_request.order_instances_by_page
  end

  def sort_key
    by_page? ? "page" : "name"
  end

  def consider_notice(ref, total, row_count)
    more = total > @offset + @limit
    return if !more && @offset.zero?

    first = @offset + 1
    last = [ @offset + @limit, total ].min
    @results << {
      display_as: NOTICE,
      reference_id: ref.id,
      first: first,
      last: last,
      total: total,
      row_count: row_count,
      next_query_string: (next_query_string(ref, last) if more),
    }
  end

  def next_query_string(ref, last)
    parts = [ "id: #{ref.id}", directive, "instance-offset: #{last}" ]
    parts << "instance-limit: #{@limit}" if @limit != Search::ParsedRequest::DEFAULT_INSTANCE_LIMIT
    parts.join(" ")
  end

  def directive
    kind = @novelties ? "novelties" : "instances"
    by_page? ? "show-#{kind}-by-page:" : "show-#{kind}:"
  end
end
