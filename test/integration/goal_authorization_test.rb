require "test_helper"

class GoalAuthorizationTest < ActionDispatch::IntegrationTest
  def setup
    @manager=create_activated_user("Manager", "manager@example.com")
    @member=create_activated_user("Member", "member@example.com")
    @outsider=create_activated_user("Outsider", "outsider@example.com")

    @goal=SavingGoal.create!(name: "旅行", target_amount: 10_000,
                             deadline: 1.month.from_now, creator: @manager)
    @manager_membership=@goal.memberships.create!(user: @manager, role: :manager)
    @member_membership=@goal.memberships.create!(user: @member, role: :member)

    @deposit=@goal.deposits.create!(member: @member, request_amount: 1_000)
  end

  test "金額が0円でもエラー画面にならず、メッセージが出る" do
    log_in_as(@member)
    assert_no_difference "Deposit.count" do
      post saving_goal_deposits_path(@goal), params: { deposit: { request_amount: 0 } }
    end
    assert_redirected_to saving_goal_path(@goal)
    assert_not_nil flash[:alert]
  end

  test "参加していない人は目標を見られない" do
    log_in_as(@outsider)
    get saving_goal_path(@goal)
    assert_response :not_found
  end

  test "参加していない人は入金を承認できない" do
    log_in_as(@outsider)
    patch confirm_deposit_path(@deposit)
    assert_response :not_found
    assert @deposit.reload.pending?
  end

  test "一般メンバーは入金を承認できない" do
    log_in_as(@member)
    patch confirm_deposit_path(@deposit)
    assert_redirected_to saving_goal_path(@goal)
    assert @deposit.reload.pending?
  end

  test "管理者は入金を承認できる" do
    log_in_as(@manager)
    patch confirm_deposit_path(@deposit)
    assert @deposit.reload.confirmed?
  end

  test "定義にないroleではメンバーを追加できない" do
    log_in_as(@manager)
    assert_no_difference "Membership.count" do
      post saving_goal_memberships_path(@goal), params: { email: @outsider.email, role: "admin" }
    end
    assert_redirected_to saving_goal_path(@goal)
    assert_not_nil flash[:alert]
  end

  test "最後の管理者は外せない" do
    log_in_as(@manager)
    assert_no_difference "Membership.count" do
      delete saving_goal_membership_path(@goal, @manager_membership)
    end
    assert_equal "最後の管理者は外せません", flash[:alert]
  end

  test "他に管理者がいれば管理者を外せる" do
    other_manager=create_activated_user("Other", "other@example.com")
    other_membership=@goal.memberships.create!(user: other_manager, role: :manager)
    log_in_as(@manager)
    assert_difference "Membership.count", -1 do
      delete saving_goal_membership_path(@goal, other_membership)
    end
  end

  test "入金申請があるメンバーは外せない" do
    log_in_as(@manager)
    assert_no_difference "Membership.count" do
      delete saving_goal_membership_path(@goal, @member_membership)
    end
  assert_redirected_to saving_goal_path(@goal)
  end

  test "目標金額より大きい入金は申請できない" do
    log_in_as(@member)
    assert_no_difference "Deposit.count" do
      post saving_goal_deposits_path(@goal), params: { deposit: { request_amount: 99_999_999_999 } }
    end
    assert_redirected_to saving_goal_path(@goal)
    assert_not_nil flash[:alert]
  end
end
