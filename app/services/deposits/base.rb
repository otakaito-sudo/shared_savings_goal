module Deposits
  class Base
    class Error < StandardError; end
    class NotAuthorized < Error; end
    class NotPending < Error; end
    class ExceedsTarget < Error; end

    def initialize(deposit:, reviewer:)
      @deposit  = deposit
      @reviewer = reviewer
    end

    private

    def authorize!
      membership = Membership.find_by(
        saving_goal_id: @deposit.saving_goal_id,
        user_id:        @reviewer.id
      )
      raise NotAuthorized unless membership&.manager?
    end

    def ensure_pending!
      raise NotPending unless @deposit.reload.pending?
    end

    def review_attributes(status)
      { status: status, reviewed_by_id: @reviewer.id, reviewed_at: Time.current }
    end
  end
end
