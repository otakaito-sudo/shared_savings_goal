require "test_helper"

class ActivitiesTest < ActionDispatch::IntegrationTest
  setup do # 管理者、メンバー、目標の作成
    @manager=create_activated_user("管理者", "manager-#{SecureRandom.hex(4)}@example.com")
    @member=create_activated_user("メンバー", "member-#{SecureRandom.hex(4)}@example.com")
    @goal=create_goal(creator: @manager)
    join(goal: @goal, user: @manager, role: :manager)
    join(goal: @goal, user: @member)
  end

  test "入金の申請と確認が履歴に残り、画面に表示される" do
    log_in_as(@member)
    assert_difference "@goal.activities.count", 1 do  # 正しい申請は履歴が残る
      post saving_goal_deposits_path(@goal), params: { deposit: { request_amount: 1000 } }
    end
    deposit=@goal.deposits.last
    assert_equal "deposit_requested", @goal.activities.recent.first.kind # 最新の申請が入金申請になっているか確認

    delete logout_path
    log_in_as(@manager)
    patch confirm_deposit_path(deposit)   # 管理者が申請を確認する

    activity=@goal.activities.recent.first  # 最新の履歴が確認で、実行者がmanager、金額が1000円であることを確認
    assert activity.deposit_confirmed?
    assert_equal @manager, activity.actor
    assert_equal 1000, activity.amount

    get saving_goal_path(@goal)         # 目標の詳細画面を開いて、履歴の文章が画面に表示されているか確認
    assert_select "ul.activities li", text: /管理者さんが1,000円の入金を確認しました/
    assert_select "ul.activities li", text: /メンバーさんが1,000円の入金を申請しました/
  end

  test "目標額に達すると達成が履歴にのこる" do
    deposit=@goal.deposits.create!(member: @member, request_amount: @goal.target_amount)    # 目標金額ピッタリの申請を作る
    log_in_as(@manager)

    patch confirm_deposit_path(deposit)

    kinds=@goal.activities.recent.limit(2).map(&:kind)          # 最新2件の履歴が達成、確認で残っている確認
    assert_equal %w[goal_achieved deposit_confirmed], kinds
  end

  test "差し戻しと再申請は、それぞれの時点の金額で残る" do
    deposit=@goal.deposits.create!(member: @member, request_amount: 1000)

    log_in_as(@manager)
    patch remand_deposit_path(deposit), params: { review_comment: "金額を確認してください" }
    delete logout_path

    log_in_as(@member)
    patch resubmit_deposit_path(deposit), params: { request_amount: 1200 }

    remanded, resubmitted=@goal.activities.order(:id).last(2)
    assert remanded.deposit_remanded?
    assert_equal 1000, remanded.amount
    assert resubmitted.deposit_resubmitted?
    assert_equal 1200, resubmitted.amount
  end

  test "処理に失敗した時には履歴を残さない" do
    deposit=@goal.deposits.create!(member: @member, request_amount: 1000)
    log_in_as(@member)

    assert_no_difference "Activity.count" do
      patch confirm_deposit_path(deposit)
    end
  end

  test "メンバーを外すと履歴に残る" do
    log_in_as(@manager)
    membership=@goal.memberships.find_by(user: @member)

    delete saving_goal_membership_path(@goal, membership)

    activity=@goal.activities.recent.first
    assert activity.member_removed?
    assert_equal @member, activity.target_user
  end
end
