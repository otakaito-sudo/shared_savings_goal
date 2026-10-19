module Deposits
  class Resubmit < Base
    def initialize(deposit:, requester:, request_amount:)
      @deposit        = deposit
      @requester      = requester
      @request_amount = request_amount
    end

    def call
      ActiveRecord::Base.transaction do
        raise NotAuthorized unless @deposit.member_id == @requester.id
        raise NotPending unless @deposit.reload.remanded?

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
