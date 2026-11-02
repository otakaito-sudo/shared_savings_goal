require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user=User.new(name: "Test", email: "test@example.com", password: "foobar")
  end

  test "作成時にactivation_digestが作られる" do
    @user.save
    assert_not_nil @user.activation_digest
  end

  test "正しいトークンならauthenticated?がtrue" do
    @user.save
    assert @user.authenticated?(:activation, @user.activation_token)
  end

  test "間違ったトークンならauthenticated?がfalse" do
    @user.save
    assert_not @user.authenticated?(:activation, "aaa")
  end

  test "ダイジェストがnilならauthenticated?がfalse" do
    # @userはsaveしていないのでactivation_digestはnil
    assert_not @user.authenticated?(:activation, "aaa")
  end

  test "再設定メールを送って2時間以内なら期限切れではない" do
    @user.save
    @user.create_reset_digest
    assert_not @user.password_reset_expired?
  end

  test "再設定メールを送って2時間を過ぎたら期限切れ" do
    @user.save
    @user.create_reset_digest
    @user.update_column(:reset_sent_at, 3.hours.ago)
    assert @user.password_reset_expired?
  end
end
