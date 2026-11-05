require "test_helper"

class RememberMeTest < ActionDispatch::IntegrationTest
  SESSION_KEY=Rails.application.config.session_options[:key]

  def setup
    ActionMailer::Base.deliveries.clear
    @user=create_activated_user("Hanako", "hanako@example.com")
  end

  # ブラウザを閉じた状態を再現する（セッションのcookieだけを消す）
  def close_browser
    cookies.delete(SESSION_KEY)
  end

  test "ログインしたままにすると、ブラウザを閉じてもログインが続く" do
    log_in_as(@user, remember_me: "1")
    assert cookies[:remember_token].present?
    assert_not_nil @user.reload.remember_digest

    close_browser
    get root_path
    assert_response :success
  end

  test "ログインしたままにしないと。ブラウザを閉じたらログアウトされる" do
    log_in_as(@user, remember_me: "0")
    assert cookies[:remember_token].blank?

    close_browser
    get root_path
    assert_redirected_to login_path
  end

  test "ログアウトすると、保持も解除される" do
    log_in_as(@user, remember_me: "1")
    delete logout_path

    assert cookies[:remember_token].blank?
    assert_nil @user.reload.remember_digest

    close_browser
    get root_path
    assert_redirected_to login_path
  end

  test "2回ログアウトしてもエラーにならない" do
    log_in_as(@user, remember_me: "1")
    delete logout_path
    delete logout_path
    assert_redirected_to login_path
  end

  test "他のブラウザでパスワードを再設定すると、保持が解除される" do
    log_in_as(@user, remember_me: "1")

    other=open_session
    other.post password_resets_path, params: { email: @user.email }
    token=ActionMailer::Base.deliveries.last.text_part.body.decoded[%r{/password_resets/([^/]+)/edit}, 1]
    other.patch password_reset_path(token), params: {
      email: @user.email,
      user: { password: "newpass", password_confirmation: "newpass" }
    }

    assert_nil @user.reload.remember_digest

    # このブラウザはログアウトされている
    close_browser
    get root_path
    assert_redirected_to login_path
  end
end
