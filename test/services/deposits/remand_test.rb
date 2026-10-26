require "test_helper"

class Deposits::RemandTest < ActiveSupport::TestCase
  setup do
    @manager=create_user(name: "管理者")
    @member=create_user(name: "メンバー")
    @goal=create_goal(creator: @manager, target_amount: 100_000)
    join(goal: @goal, user: @manager, role: :manager)
    join(goal: @goal, user: @member)
  end

  test "差し戻しには理由が必須" do
    deposit=create_deposit(5_000)

    assert_raises(Deposits::Remand::CommentRequired) do
      Deposits::Remand.new(deposit: deposit, reviewer: @manager, comment: "").call
    end
    assert deposit.reload.pending?, "失敗時は状態が変わらない"
  end

  test "差し戻すと理由が記録される" do
    deposit=create_deposit(5_000)
    Deposits::Remand.new(deposit: deposit, reviewer: @manager, comment: "領収書の金額と違います").call

    assert deposit.reload.remanded?
    assert_equal "領収書の金額と違います", deposit.review_comment
    assert_equal @manager, deposit.reviewer
  end

  test "差し戻し中の申請は現在額に含まれない" do
    deposit=create_deposit(5_000)
    Deposits::Remand.new(deposit: deposit, reviewer: @manager, comment: "理由").call

    assert_equal 0, @goal.reload.current_amount
  end

  test "確認済み・却下の申請は差し戻しできない" do
    confirmed=create_deposit(1_000)
    Deposits::Confirm.new(deposit: confirmed, reviewer: @manager).call
    assert_raises(Deposits::Base::NotPending) do
      Deposits::Remand.new(deposit: confirmed, reviewer: @manager, comment: "理由").call
    end

    rejected=create_deposit(1_000)
    Deposits::Reject.new(deposit: rejected, reviewer: @manager).call
    assert_raises(Deposits::Base::NotPending) do
      Deposits::Remand.new(deposit: rejected, reviewer: @manager, comment: "理由").call
    end
  end

  test "差し戻された申請を修正して再申請できる" do
    deposit=remanded_deposit(5_000)
    Deposits::Resubmit.new(deposit: deposit, requester: @member, request_amount: 4_800).call

    assert deposit.reload.pending?
    assert_equal 4_800, deposit.request_amount
    assert_nil deposit.reviewed_at, "確認情報がリセットされる"
    assert_nil deposit.reviewed_by_id
  end

  test "申請者本人以外は再申請できない" do
    deposit=remanded_deposit(5_000)
    assert_raises(Deposits::Resubmit::NotAuthorized) do
      Deposits::Resubmit.new(deposit: deposit, requester: @manager, request_amount: 4_800).call
    end
  end

  test "差し戻し中でない申請は再申請できない" do
    deposit=create_deposit(5_000)

    assert_raises(Deposits::Resubmit::NotRemanded) do
      Deposits::Resubmit.new(deposit: deposit, requester: @member, request_amount: 4_800).call
    end
  end

  test "差し戻し中に目標が達成したら再申請できない" do
    deposit1=remanded_deposit(5_000)
    deposit2=create_deposit(100_000)
    Deposits::Confirm.new(deposit: deposit2, reviewer: @manager).call

    assert @goal.reload.achieved?
    assert_raises(Deposits::Resubmit::GoalClosed) do
      Deposits::Resubmit.new(deposit: deposit1, requester: @member, request_amount: 4_800).call
    end
    assert deposit1.remanded?, "状態は差し戻しのまま"
  end

  test "中止された目標にも再申請できない" do
    remanded=remanded_deposit(5_000)
    @goal.canceled!

    assert_raise(Deposits::Resubmit::GoalClosed) do
      Deposits::Resubmit.new(deposit: remanded, requester: @member, request_amount: 4_800).call
    end
  end

  private

  def create_deposit(amount)
    Deposit.create!(saving_goal: @goal, member: @member, request_amount: amount)
  end

  def remanded_deposit(amount)
    deposit=create_deposit(amount)
    Deposits::Remand.new(deposit: deposit, reviewer: @manager, comment: "理由").call
    deposit
  end
end
