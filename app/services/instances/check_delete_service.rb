# frozen_string_literal: true

module Instances
  # Delegates to the check_delete_instance database function so the delete
  # rules live in one place - the database.
  class CheckDeleteService < BaseService
    Result = Struct.new(:action_code, :delete_action, :explanation) do
      # deletion is blocked
      def delete_blocked? = delete_action == "BLOCK"

      # deletion is allowed, but the instance should be soft-deleted
      def soft_delete_allowed? = delete_action == "SOFT_DELETE"

      # deletion is allowed, and the instance can be hard-deleted
      def hard_delete_allowed? = delete_action == "DELETE"
    end

    attr_reader :result

    def initialize(instance:)
      super({})
      @instance = instance
    end

    def execute
      row = ActiveRecord::Base.connection.select_one(
        ActiveRecord::Base.sanitize_sql(
          ["SELECT action_code, delete_action, explanation
            FROM check_delete_instance(?)", @instance.id]
        )
      )
      @result = Result.new(row["action_code"], row["delete_action"],
        row["explanation"])
    end
  end
end
