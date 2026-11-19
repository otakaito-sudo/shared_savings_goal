module Deposits
  class Reject < Base
    def call
      ActiveRecord::Base.transaction do
        authorize!
        ensure_pending!
        @deposit.update!(review_attributes(:rejected))
        record_activity!(:deposit_rejected)
        @deposit
      end
    end
  end
end
