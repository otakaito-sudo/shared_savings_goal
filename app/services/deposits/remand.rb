module Deposits
  class Remand < Base
    class CommentRequired < Error; end

    def initialize(deposit:, reviewer:, comment:)
      super(deposit: deposit, reviewer: reviewer)
      @comment = comment
    end

    def call
      raise CommentRequired if @comment.blank?

      ActiveRecord::Base.transaction do
        authorize!
        ensure_pending!
        @deposit.update!(review_attributes(:remanded).merge(review_comment: @comment))
        @deposit
      end
    end
  end
end
