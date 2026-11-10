require "test_helper"

class InvitationsRevocationTest < ActionDispatch::IntegrationTest
  setup do
    @manager=create_activated_user("管理者", "manager-#{SecureRandom.hex(4)}@example.com")
    @goal=create_goal(creator: @manager)
    join(goal: @goal, user: @manager, role: :manager)

    @invitee=create_activated_user("招待された人", "invitee-#{SecureRandom.hex(4)}@example.com")
    @invitation=Invitation.create!(saving_goal: @goal, invited_by: @manager, email: @invitee.email)
    @token=@invitation.token
  end

  test "管理者は承諾待ちの招待を確認して取り消せる" do
    log_in_as(@manager)

    get saving_goal_path(@goal)
    assert_select "h3", text: "承諾待ちの招待"
    assert_select "li", text: /#{Regexp.escape(@invitee.email)}/

    delete saving_goal_invitation_path(@goal, @invitation)
    assert_redirected_to saving_goal_path(@goal)
    assert @invitation.reload.revoked_at.present?

    follow_redirect!
    assert_select "h3", text: "承諾待ちの招待", count: 0
    assert_select "li", text: /#{Regexp.escape(@invitee.email)}/, count: 0
  end

  test "取り消した招待は承諾できない" do
    log_in_as(@manager)
    delete saving_goal_invitation_path(@goal, @invitation)
    delete logout_path

    log_in_as(@invitee)
    assert_no_difference "Membership.count" do
      post accept_invitation_path(@invitation), params: { token: @token }
    end
  end

  test "管理者ではないメンバーには一覧がみえず。取り消しもできない" do
    member=create_activated_user("メンバー", "member-#{SecureRandom.hex(4)}@example.com")
    join(goal: @goal, user: member)
    log_in_as(member)

    get saving_goal_path(@goal)
    assert_not_includes response.body, @invitee.email

    delete saving_goal_invitation_path(@goal, @invitation)
    assert_nil @invitation.reload.revoked_at
  end

  test "別の目標のURLからは取り消せない" do
    other_goal=create_goal(creator: @manager)
    join(goal: other_goal, user: @manager, role: :manager)
    log_in_as(@manager)

    delete saving_goal_invitation_path(other_goal, @invitation)
    assert_response :not_found
    assert_nil @invitation.reload.revoked_at
  end

  test "承諾済みの招待は取り消せない" do
    @invitation.update!(accepted_at: Time.current)
    log_in_as(@manager)

    delete saving_goal_invitation_path(@goal, @invitation)
    assert_nil @invitation.reload.revoked_at
  end
end
