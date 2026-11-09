require "test_helper"

class InvitationsSendingTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
    @manager=create_activated_user("管理者", "manager-#{SecureRandom.hex(4)}@example.com")
    @goal=create_goal(creator: @manager)
    join(goal: @goal, user: @manager, role: :manager)
    @invitee_email="invitee-#{SecureRandom.hex(4)}@exmaple.com"
  end

  test "管理者が招待を送り、メールのリンクから承諾できる" do
    log_in_as(@manager)

    assert_difference "Invitation.count", 1 do
      assert_emails 1 do
        post saving_goal_invitations_path(@goal), params: { email: @invitee_email }
      end
    end
    assert_redirected_to saving_goal_path(@goal)

    invitation=Invitation.last
    mail=ActionMailer::Base.deliveries.last
    assert_equal [ @invitee_email ], mail.to

    body=mail.text_part.body.decoded
    token=body[%r{/invitations/#{invitation.id}\?token=([\w\-]+)}, 1]
    assert token.present?
    assert_not_includes body, invitation.token_digest

    # 招待された人がアカウントを作って承諾する
    delete logout_path
    invitee=create_activated_user("招待された人", @invitee_email)
    log_in_as(invitee)

    assert_difference "Membership.count", 1 do
      post accept_invitation_path(invitation), params: { token: token }
    end
    assert @goal.memberships.exists?(user: invitee, role: :member)
  end

  test "管理者ではないメンバーは招待できない" do
    member=create_activated_user("メンバー", "member-#{SecureRandom.hex(4)}@example.com")
    join(goal: @goal, user: member)
    log_in_as(member)
    assert_no_difference "Invitation.count" do
      assert_no_emails do
        post saving_goal_invitations_path(@goal), params: { email: @invitee_email }
      end
    end
  end

  test "参加済みの人には招待しない" do
    member = create_activated_user("メンバー", "member-#{SecureRandom.hex(4)}@example.com")
    join(goal: @goal, user: member)
    log_in_as(@manager)

    assert_no_difference "Invitation.count" do
      post saving_goal_invitations_path(@goal), params: { email: member.email.upcase }
    end
  end

  test "不正なメールアドレスでは招待しない" do
    log_in_as(@manager)

    assert_no_emails do
      post saving_goal_invitations_path(@goal), params: { email: "invalid" }
    end
  end

  test "再送すると古い招待は取り消される" do
    log_in_as(@manager)

    post saving_goal_invitations_path(@goal), params: { email: @invitee_email }
    old = Invitation.last
    post saving_goal_invitations_path(@goal), params: { email: @invitee_email }

    assert old.reload.revoked_at.present?
    assert Invitation.last.active?
  end

  test "募集していない目標には招待できない" do
    @goal.update!(status: :canceled)
    log_in_as(@manager)

    assert_no_difference "Invitation.count" do
      post saving_goal_invitations_path(@goal), params: { email: @invitee_email }
    end
  end

  test "期限を過ぎた目標には招待できない" do
    @goal.update_columns(deadline: Date.yesterday)
    log_in_as(@manager)

    assert_no_difference "Invitation.count" do
      post saving_goal_invitations_path(@goal), params: { email: @invitee_email }
    end
  end
end
