require "test_helper"

class DepositTest < ActiveSupport::TestCase
  setup do
    @user=create_user
    @outsider = create_user(name: "部外者")
    @goal=create_goal(creator: @user)
    join(goal: @goal, user: @user)
  end

  test "参加メンバーのみ申請できる" do
    assert Deposit.new(saving_goal: @goal, member: @user, request_amount: 1_000).valid?
    assert_not Deposit.new(saving_goal: @goal, member: @outsider, request_amount: 1_000).valid?
  end

  test "未参加者の申請はDB制約でも拒否される" do
    deposit=Deposit.new(saving_goal: @goal, member: @outsider, request_amount: 1_000)
    assert_raises(ActiveRecord::InvalidForeignKey) { deposit.save!(validate: false) }
  end

  test "達成・中止した目標には申請できない" do
    @goal.achieved!
    assert_not Deposit.new(saving_goal: @goal, member: @user, request_amount: 1_000).valid?
    @goal.canceled!
    assert_not Deposit.new(saving_goal: @goal, member: @user, request_amount: 1_000).valid?
  end

  test "金額は1円以上の整数" do
    assert_not Deposit.new(saving_goal: @goal, member: @user, request_amount: 0).valid?
  end
end
