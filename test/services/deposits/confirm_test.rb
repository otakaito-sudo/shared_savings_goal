require "test_helper"

class Deposits::ConfirmTest < ActiveSupport::TestCase
  setup do
    @manager=create_user(name: "管理者")
    @member=create_user(name: "メンバー")
    @goal=create_goal(creator: @manager, target_amount: 100_000)
    join(goal: @goal, user: @manager, role: :manager)
    join(goal: @goal, user: @member)
  end

  test "確認すると現在額に反映され確認者が記録される" do
    deposit=create_deposit(60_000)
    Deposits::Confirm.new(deposit: deposit, reviewer: @manager).call

    assert deposit.reload.confirmed?
    assert_equal @manager, deposit.reviewer
    assert_not_nil deposit.reviewed_at
    assert_equal 60_000, @goal.reload.current_amount
  end

  test "目標金額を超える確認はできない" do
    Deposits::Confirm.new(deposit: create_deposit(60_000), reviewer: @manager).call
    over=create_deposit(50_000)

    assert_raises(Deposits::Base::ExceedsTarget) do
      Deposits::Confirm.new(deposit: over, reviewer: @manager).call
    end
    assert over.reload.pending?
    assert_equal 60_000, @goal.reload.current_amount
  end

  test "目標金額に達すると達成になる" do
    Deposits::Confirm.new(deposit: create_deposit(100_000), reviewer: @manager).call
    assert @goal.reload.achieved?
  end

  test "同じ申請を二重に確認できない" do
    deposit=create_deposit(1_000)
    Deposits::Confirm.new(deposit: deposit, reviewer: @manager).call

    assert_raises(Deposits::Base::NotPending) do
      Deposits::Confirm.new(deposit: deposit, reviewer: @manager).call
    end
    assert_equal 1_000, @goal.reload.current_amount
  end

  test "管理者以外は確認できない" do
    assert_raises(Deposits::Base::NotAuthorized) do
      Deposits::Confirm.new(deposit: create_deposit(1_000), reviewer: @member).call
    end
  end

  private

  def create_deposit(amount)
    Deposit.create!(saving_goal: @goal, member: @member, request_amount: amount)
  end
end
