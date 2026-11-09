require "test_helper"

class InvitationsAcceptanceTest < ActionDispatch::IntegrationTest
  setup do
    @inviter=create_activated_user(
      "招待する人",
      "inviter-#{SecureRandom.hex(4)}@example.com"
    )
    @invitee=create_activated_user(
      "招待された人",
      "invitee-#{SecureRandom.hex(4)}@example.com"
    )

    @goal=create_goal(creator: @inviter)
    join(goal: @goal, user: @inviter, role: :manager)

    @invitation = Invitation.create!(
      saving_goal: @goal,
      invited_by: @inviter,
      email: @invitee.email
    )
    @token=@invitation.token
  end

  test "確認画面を開くだけでは参加せず承諾すると参加する" do
    log_in_as(@invitee)

    assert_no_difference "Membership.count" do
      get invitation_path(@invitation), params: { token: @token }
    end
    assert_response :success

    assert_difference "Membership.count", 1 do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to saving_goal_path(@goal)
    assert @goal.memberships.exists?(user: @invitee, role: :member)
    assert @invitation.reload.accepted_at.present?

    # 使用済みリンクは再利用できない
    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end
    assert_redirected_to root_path
  end

  test "未ログインでは承諾できない" do
    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to login_path
    assert_nil @invitation.reload.accepted_at
  end

  test "別のメールアドレスのユーザーは承諾できない" do
    other=create_activated_user(
      "別の人",
      "other-#{SecureRandom.hex(4)}@example.com"
    )
    log_in_as(other)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "有効化されていないユーザーは承諾できない" do
    log_in_as(@invitee)
    @invitee.update_columns(activated: false)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "間違ったトークンでは承諾できない" do
    log_in_as(@invitee)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: "wrong" }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "期限切れの招待は承諾できない" do
    log_in_as(@invitee)
    @invitation.update!(expires_at: 1.minute.ago)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "取り消された招待は承諾できない" do
    log_in_as(@invitee)
    @invitation.update!(revoked_at: Time.current)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "募集していない目標には参加できない" do
    log_in_as(@invitee)
    @goal.update!(status: :canceled)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to root_path
    assert_nil @invitation.reload.accepted_at
  end

  test "すでに参加している場合は重複して追加しない" do
    join(goal: @goal, user: @invitee)
    log_in_as(@invitee)

    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end

    assert_redirected_to saving_goal_path(@goal)
  end
end
