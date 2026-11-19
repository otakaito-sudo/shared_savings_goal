require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end

  # メール本文からトークンを取り出す
  def token_from(mail)
    mail.text_part.body.decoded[%r{/account_activations/([^/]+)/edit}, 1]
  end

  test "登録してメールで有効化するとログインできる" do
    # 登録するとユーザーが1人増える
    assert_difference "User.count", 1 do
      post users_path, params: { user: { name: "Test", email: "test@example.com", password: "foobar" } }
    end

    # メールが1通送られる
    assert_equal 1, ActionMailer::Base.deliveries.size

    # 登録直後はログインしていない・有効化していない
    user=User.find_by(email: "test@example.com")
    assert_not user.activated?
    assert_nil session[:user_id]

    # 間違ったトークンでは有効化できない
    get edit_account_activation_path("invalid", email: user.email)
    assert_not user.reload.activated?

    # 正しいトークンでも、メールアドレスが違うと有効化できない
    token=token_from(ActionMailer::Base.deliveries.last)
    get edit_account_activation_path(token, email: "wrong@example.com")
    assert_not user.reload.activated?

    # 正しいトークンとメーアドレスなら有効化してログインできる
    get edit_account_activation_path(token, email: user.email)
    assert user.reload.activated?
    assert_equal user.id, session[:user_id]
  end

  test "24時間を過ぎた有効化リンクは使えず、ログインすると再送される" do
    post users_path, params: { user: { name: "Test", email: "test@example.com", password: "foobar" } }
    user=User.find_by(email: "test@example.com")
    old_token=token_from(ActionMailer::Base.deliveries.last)

    travel 25.hours do
      # 期限切れのリンクでは有効化できない
      get edit_account_activation_path(old_token, email: user.email)
      assert_redirected_to login_path
      assert_not user.reload.activated?

      # ログインすると新しいメールが届く
      log_in_as(user)
      new_token=token_from(ActionMailer::Base.deliveries.last)
      assert_not_equal old_token, new_token

      # 新しいリンクなら有効化できる
      get edit_account_activation_path(new_token, email: user.email)
      assert user.reload.activated?
    end
  end
end
