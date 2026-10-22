# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

# NSL-6001: caps how many standalone instances a reference search expands
# per reference, in SQL rather than in Ruby, so a reference with tens of
# thousands of instances doesn't load them all just to show the first
# 1000.
#
# Extended by Instance::AsArray::ForReference and its ForNovelties
# variant. Each defines standalone_scope(reference_ids), the standalone
# instances it lists (relationship instances are only ever shown under
# their standalone, via cited_by), and base_query(sort_by).
#
# offset and limit count standalone instances, so a standalone and the
# synonymy shown beneath it are never split. Ranks are numbered within
# each reference, in the same order the instances are shown, with
# instance.id breaking ties so pages don't overlap or skip.
module Instance::AsArray::ForReference::Windowable
  ORDER_BY_NAME_SQL = "simple_name asc"
  # Same expression as the Instance.ordered_by_page scope.
  ORDER_BY_PAGE_SQL = <<-SQL
    Lpad(
      Regexp_replace(
        Regexp_replace(instance.page, '[A-z. ]','','g'),
            '[^0-9]*([0-9][0-9]*).*', '\\1')
            ||
            Regexp_replace(
              Regexp_replace(
                Regexp_replace(instance.page, '.*-.*', '~'),
              '[^~].*','0'),
              '~','Z'),
          12,'0'),
          page,
          name.full_name
  SQL
  RANK_BY_NAME_SQL = "instance.id, row_number() over (partition by instance.reference_id " \
                     "order by #{ORDER_BY_NAME_SQL}, instance.id) as instance_rank"
  RANK_BY_PAGE_SQL = "instance.id, row_number() over (partition by instance.reference_id " \
                     "order by #{ORDER_BY_PAGE_SQL}, instance.id) as instance_rank"

  def rank_select_sql(sort_by)
    sort_by == "page" ? RANK_BY_PAGE_SQL : RANK_BY_NAME_SQL
  end

  # Standalone instances for the given references, ordered as shown and
  # restricted to ranks offset+1 .. offset+limit within each reference.
  # A nil limit means no upper bound.
  def windowed_query(reference_ids, sort_by, offset: 0, limit: nil)
    query = base_query(sort_by).where(reference_id: reference_ids, cited_by_id: nil)
      .order(Arel.sql("instance.id"))
    offset ||= 0
    return query if offset.zero? && limit.nil?

    ranked = standalone_scope(reference_ids).joins(:name).select(Arel.sql(rank_select_sql(sort_by)))
    # A subquery in the WHERE, not a join: a joined SQL string naming name
    # or instance_type makes Rails alias base_query's own joins to them.
    window = Instance.unscoped.from(ranked, :ranked_instance)
      .where("ranked_instance.instance_rank > ?", offset)
    window = window.where("ranked_instance.instance_rank <= ?", offset + limit) if limit
    query.where(id: window.select("ranked_instance.id"))
  end

  # { reference_id => number of standalone instances }, in one query.
  def standalone_counts_for(reference_ids)
    return {} if reference_ids.empty?

    standalone_scope(reference_ids).group(:reference_id).count
  end
end
