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

  private

  def build(**attrs)
    SavingGoal.new({ name: "旅行", target_amount: 100_000,
                      deadline: Date.current + 30, creator: @user }.merge(attrs))
  end
end
