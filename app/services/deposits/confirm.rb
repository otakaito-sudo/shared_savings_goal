module Deposits
  class Confirm
    class Error < StandardError; end
    class NotAuthorized < Error; end
    class NotPending < Error; end
    class ExceedsTarget < Error; end

    def initialize(deposit:, reviewer:)
      @deposit  = deposit
      @reviewer = reviewer
    end

    def call
      ActiveRecord::Base.transaction do
        goal = SavingGoal.lock.find(@deposit.saving_goal_id)

        authorize!(goal)
        raise NotPending unless @deposit.reload.pending?

        confirmed_total = goal.deposits.confirmed.sum(:request_amount)
        new_total = confirmed_total + @deposit.request_amount
        raise ExceedsTarget if new_total > goal.target_amount

        @deposit.update!(
          status:         :confirmed,
          reviewed_by_id: @reviewer.id,
          reviewed_at:    Time.current
        )

        goal.achieved! if new_total == goal.target_amount

        @deposit
      end
    end

    private

    def authorize!(goal)
      membership = Membership.find_by(saving_goal_id: goal.id, user_id: @reviewer.id)
      raise NotAuthorized unless membership&.manager?
    end
  end
end
