require "test_helper"

class SavingGoalTest < ActiveSupport::TestCase
  setup do
    @user=create_user
  end

  test "目標金額は1円以上の整数" do
    assert build(target_amount: 1).valid?
    assert_not build(target_amount: 0).valid?
    assert_not build(target_amount: -1).valid?
    assert_not build(target_amount: 1.5).valid?
  end

  test "期限は作成日以降" do
    assert build(deadline: Date.current).valid?
    assert_not build(deadline: Date.current - 1).valid?
  end

  test "作成後は期限が過去になっても更新できる" do
    goal=create_goal(creator: @user)
    goal.update_column(:deadline, Date.current - 10)
    goal.name="名称変更"
    assert goal.valid?, "on: :create のため更新時は期限を検証しない"
  end

  test "現在額は確認済みの申請のみ合計する" do
    goal=create_goal(creator: @user)
    join(goal: goal, user: @user)
    Deposit.create!(saving_goal: goal, member: @user, request_amount: 1_000)
    Deposit.create!(saving_goal: goal, member: @user, request_amount: 2_000,
                    status: :confirmed)
    assert_equal 2_000, goal.current_amount
  end

test "期限日の当日までは受付中で、翌日から締め切る" do
  goal = create_goal(creator: create_user(email: "deadline-#{SecureRandom.hex(4)}@example.com"))
  goal.update_columns(deadline: Date.current)

  assert goal.open?
  assert_equal :recruiting, goal.display_status

  travel 1.day do
    assert goal.deadline_passed?
    assert_not goal.open?
    assert_not goal.accepting_deposits?
    assert_equal :expired, goal.display_status
  end
end

test "中止した目標は期限内でも受け付けない" do
  goal = create_goal(creator: create_user(email: "canceled-#{SecureRandom.hex(4)}@example.com"))
  goal.update!(status: :canceled)

  assert_not goal.open?
  assert_equal :canceled, goal.display_status
end

  private

  def build(**attrs)
    SavingGoal.new({ name: "旅行", target_amount: 100_000,
                      deadline: Date.current + 30, creator: @user }.merge(attrs))
  end
end
