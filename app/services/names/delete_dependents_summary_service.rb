# frozen_string_literal: true

module Names
  # NOTES: Summarises the records that will be removed along with a name.
  #
  # Each group is counted by the "thing" that identifies it, so the delete
  # warning can show how many records are involved rather than listing every
  # one of them:
  #
  #   name_resource   counted by resource_host.name
  #   name_resources  counted by resource_type.description
  #   name_tag_name   counted by name_tag.name
  class DeleteDependentsSummaryService < BaseService
    UNLABELLED = "(unnamed)"

    # NOTES: The tables behind the "Resources" group. They are legacy and are planned for
    # removal, so their presence is checked before they are queried.
    LEGACY_RESOURCE_TABLES = %w[name_resources resource resource_type].freeze

    Group = Struct.new(:label, :entries) do
      # NOTES: Entries is an array of [label, count] pairs
      def total = entries.sum(&:last)
    end

    attr_reader :groups

    def initialize(name:)
      super({})
      @name = name
    end

    def execute
      @groups = [
        group("Name resources", name_resources_by_host),
        group("Resources", resources_by_type),
        group("Name tags", tags_by_tag)
      ].compact
    end

    def any? = groups.present?

    private

    def group(label, entries)
      return if entries.empty?

      Group.new(label, entries)
    end

    # NOTES: name_resource joined to resource_host
    def name_resources_by_host
      labelled(
        @name.name_resources
          .joins(:resource_host)
          .group("resource_host.name")
          .order("resource_host.name")
          .count(:all)
      )
    end

    # NOTES: name_tag_name joined to name_tag
    def tags_by_tag
      labelled(
        @name.name_tag_names
          .joins(:name_tag)
          .group("name_tag.name")
          .order("name_tag.name")
          .count(:all)
      )
    end

    # NOTES: name_resources joined to resource then resource_type.
    # These tables have no models, so the grouping is done in SQL.
    #
    # name_resources is legacy and is expected to be dropped. Once any of the
    # tables it needs has gone the group is simply left out of the summary.
    def resources_by_type
      return [] unless legacy_resource_tables?

      labelled(
        ActiveRecord::Base.connection.select_rows(
          ActiveRecord::Base.sanitize_sql(
            ["SELECT resource_type.description, count(*)
                FROM name_resources
                JOIN resource
                  ON resource.id = name_resources.resource_id
                JOIN resource_type
                  ON resource_type.id = resource.resource_type_id
               WHERE name_resources.name_id = ?
               GROUP BY resource_type.description
               ORDER BY resource_type.description", @name.id]
          )
        )
      )
    end

    def legacy_resource_tables?
      connection = ActiveRecord::Base.connection
      LEGACY_RESOURCE_TABLES.all? { |table| connection.table_exists?(table) }
    end

    def labelled(counts)
      counts.map { |label, count| [label.presence || UNLABELLED, count.to_i] }
    end
  end
end
