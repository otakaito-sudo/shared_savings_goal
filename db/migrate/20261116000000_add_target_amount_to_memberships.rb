class AddTargetAmountToMemberships < ActiveRecord::Migration[8.1]
  class Goal < ActiveRecord::Base
    self.table_name = "saving_goals"
  end

  class Member < ActiveRecord::Base
    self.table_name = "memberships"
  end

  def up
    add_column :memberships, :target_amount, :integer, null: false, default: 0
    add_check_constraint :memberships, "target_amount >= 0 AND target_amount <= 100000000", name: "memberships_target_amount_valid"

    # 既存データは作成者（不在時はリーダー、さらに不在時は先頭の参加者）へ
    # 仮配分する。リーダーが編集画面で希望する配分に変更できる。
    Goal.reset_column_information
    Member.reset_column_information
    Goal.find_each do |goal|
      members = Member.where(saving_goal_id: goal.id)
      recipient = members.find_by(user_id: goal.created_by_id) || members.where(role: 1).order(:id).first || members.order(:id).first
      recipient&.update_columns(target_amount: goal.target_amount)
    end
  end

  def down
    remove_check_constraint :memberships, name: "memberships_target_amount_valid"
    remove_column :memberships, :target_amount
  end
end
