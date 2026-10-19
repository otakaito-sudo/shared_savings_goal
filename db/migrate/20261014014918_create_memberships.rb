class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :saving_goal, null: false, foreign_key: true
      t.references :user,        null: false, foreign_key: true
      t.integer    :role,        null: false, default: 0
      t.timestamps
    end

    add_index :memberships, [ :saving_goal_id, :user_id ], unique: true
    add_check_constraint :memberships, "role BETWEEN 0 AND 1",
      name: "memberships_role_valid"
  end
end
