module Names
  class CheckDeleteService < BaseService
    Result = Struct.new(:action_code, :delete_action, :explanation) do
      # deletion is blocked
      def delete_blocked? = delete_action == "BLOCK"

      # deletion is allowed, but the name should be soft-deleted
      def soft_delete_allowed? = delete_action == "SOFT_DELETE"

      # deletion is allowed, and the name can be hard-deleted
      def hard_delete_allowed? = delete_action == "DELETE"
    end

    attr_accessor :result

    def initialize(name:)
      super({})
      @name = name
    end

    def execute
      row = ActiveRecord::Base.connection.select_one(
        ActiveRecord::Base.sanitize_sql(
          ["SELECT action_code, delete_action, explanation
            FROM check_delete_name(?)", @name.id]
        )
      )
      @result = Result.new(row["action_code"], row["delete_action"],
        row["explanation"])
    end
  end
end
