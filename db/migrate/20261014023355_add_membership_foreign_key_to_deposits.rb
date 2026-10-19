class AddMembershipForeignKeyToDeposits < ActiveRecord::Migration[8.1]
  def change
    add_index :deposits, [ :saving_goal_id, :member_id ]

    add_foreign_key :deposits, :memberships,
      column: [ :saving_goal_id, :member_id ],
      primary_key: [ :saving_goal_id, :user_id ],
      name: "fk_deposits_membership"
  end
end
