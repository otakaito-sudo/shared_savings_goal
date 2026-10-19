module Deposits
  class Confirm < Base
    def call
      ActiveRecord::Base.transaction do
        goal = SavingGoal.lock.find(@deposit.saving_goal_id)

        authorize!
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
  end
end
