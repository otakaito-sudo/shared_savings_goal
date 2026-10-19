class CreateSavingGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :saving_goals do |t|
      t.string     :name,          null: false
      t.string     :purpose
      t.integer    :target_amount, null: false
      t.date       :deadline,      null: false
      t.integer    :status,        null: false, default: 0
      t.references :created_by,    null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_check_constraint :saving_goals, "target_amount >= 1",
      name: "saving_goals_taget_amount_positive"
    add_check_constraint :saving_goals, "status BETWEEN 0 AND 2",
      name: "saving_goals_status_valid"
  end
end
