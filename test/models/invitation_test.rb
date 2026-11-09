require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @inviter=create_user(email: "inviter@example.com")
    @goal=create_goal(creator: @inviter)

    @invitation=Invitation.create!(
      saving_goal: @goal,
      invited_by: @inviter,
      email: "FRIEND@EXAMPLE.COM"
    )
  end

  test "メールアドレスを正規化トークンのダイジェストを保存する" do
    assert_equal "friend@example.com", @invitation.email
    assert @invitation.token.present?
    assert @invitation.token_digest.present?
    assert_not_equal @invitation.token, @invitation.token_digest
    assert @invitation.authenticated?(@invitation.token)
    assert_not @invitation.authenticated?("wrong_token")
    assert_not @invitation.authenticated?(nil)
  end

  test "新しい招待は有効" do
    assert @invitation.active?
  end

  test "期限になると招待は無効" do
    travel_to @invitation.expires_at+1.second do
      assert @invitation.expired?
      assert_not @invitation.active?
    end
  end

  test "承諾済みの招待は無効" do
    @invitation.update!(accepted_at: Time.current)

    assert_not @invitation.active?
  end

  test "取り消し済みの招待は無効" do
    @invitation.update!(revoked_at: Time.current)

    assert_not @invitation.active?
  end

  test "不正なメールアドレスでは保存できない" do
    invitation=Invitation.new(
      saving_goal: @goal,
      invited_by: @inviter,
      email: "invalid-email"
    )

    assert_not invitation.valid?
    assert invitation.errors[:email].present?
  end
end
