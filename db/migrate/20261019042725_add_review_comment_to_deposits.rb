class AddReviewCommentToDeposits < ActiveRecord::Migration[8.1]
  def change
    add_column :deposits, :review_comment, :text
  end
end
