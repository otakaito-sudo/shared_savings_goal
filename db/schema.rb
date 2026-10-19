# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_19_042725) do
  create_table "deposits", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "request_amount", null: false
    t.bigint "member_id", null: false
    t.bigint "saving_goal_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "review_comment"
    t.index ["member_id"], name: "index_deposits_on_member_id"
    t.index ["reviewed_by_id"], name: "index_deposits_on_reviewed_by_id"
    t.index ["saving_goal_id", "member_id"], name: "index_deposits_on_saving_goal_id_and_member_id"
    t.index ["saving_goal_id"], name: "index_deposits_on_saving_goal_id"
    t.check_constraint "`request_amount` >= 1", name: "deposits_request_amount_positive"
    t.check_constraint "`status` between 0 and 3", name: "deposits_status_valid"
  end

  create_table "memberships", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "saving_goal_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["saving_goal_id", "user_id"], name: "index_memberships_on_saving_goal_id_and_user_id", unique: true
    t.index ["saving_goal_id"], name: "index_memberships_on_saving_goal_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "`role` between 0 and 1", name: "memberships_role_valid"
  end

  create_table "saving_goals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "purpose"
    t.integer "target_amount", null: false
    t.date "deadline", null: false
    t.integer "status", default: 0, null: false
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_saving_goals_on_created_by_id"
    t.check_constraint "`status` between 0 and 2", name: "saving_goals_status_valid"
    t.check_constraint "`target_amount` >= 1", name: "saving_goals_taget_amount_positive"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "activation_digest"
    t.boolean "activated", default: false, null: false
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "deposits", "memberships", column: ["saving_goal_id", "member_id"], primary_key: ["saving_goal_id", "user_id"], name: "fk_deposits_membership"
  add_foreign_key "deposits", "saving_goals"
  add_foreign_key "deposits", "users", column: "member_id"
  add_foreign_key "deposits", "users", column: "reviewed_by_id"
  add_foreign_key "memberships", "saving_goals"
  add_foreign_key "memberships", "users"
  add_foreign_key "saving_goals", "users", column: "created_by_id"
end
