module Deposits
  class Resubmit < Base
    class NotRemanded < Error; end
    class GoalClosed < Error; end

    def initialize(deposit:, requester:, request_amount:)
      super(deposit: deposit, reviewer: requester)
      @requester      = requester
      @request_amount = request_amount
    end

    def call
      ActiveRecord::Base.transaction do
        @deposit.reload
        raise NotAuthorized unless @deposit.member_id == @requester.id
        raise NotRemanded unless @deposit.reload.remanded?
        raise GoalClosed unless @deposit.saving_goal.recruiting?

        @deposit.update!(
          request_amount: @request_amount,
          status:         :pending,
          reviewed_by_id: nil,
          reviewed_at:    nil
        )
        @deposit
      end
    end
  end
end
