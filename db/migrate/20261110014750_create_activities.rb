class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :saving_goal, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :target_user, foreign_key: { to_table: :users }
      t.references :deposit, foreign_key: true
      t.integer :kind, null: false
      t.integer :amount

      t.timestamps
    end

    add_index :activities, [ :saving_goal_id, :created_at ]
  end
end
