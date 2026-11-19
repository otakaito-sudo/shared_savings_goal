class CreateDeposits < ActiveRecord::Migration[8.1]
  def change
    create_table :deposits do |t|
      t.integer    :request_amount, null: false
      t.references :saving_goal,    null: false, foreign_key: true
      t.references :member,         null: false, foreign_key: { to_table: :users }
      t.integer    :status,         null: false, default: 0
      t.datetime   :reviewed_at
      t.references :reviewed_by,    foreign_key: { to_table: :users }
      t.integer    :lock_version,   null: false, default: 0
      t.timestamps
    end

    add_check_constraint :deposits, "request_amount >= 1",
      name: "deposits_request_amount_positive"
    add_check_constraint :deposits, "status BETWEEN 0 AND 3",
      name: "deposits_status_valid"
  end
end
