module Deposits
  class Reject < Base
    def call
      ActiveRecord::Base.transaction do
        authorize!
        ensure_pending!
        @deposit.update!(review_attributes(:rejected))
        @deposit
      end
    end
  end
end
