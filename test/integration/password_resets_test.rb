require "test_helper"

class PasswordResetsTest < ActionDispatch::IntegrationTest
  MESSAGE="入力されたメールアドレスが登録されている場合、再設定メールを送信しました"

  def setup
    ActionMailer::Base.deliveries.clear
    @user=User.create!(name: "Test", email: "test@example.com", password: "foobar")
    @user.update_columns(activated: true, activated_at: Time.zone.now)
  end

  def token_from(mail)
    mail.text_part.body.decoded[%r{/password_resets/([^/]+)/edit}, 1]
  end

  def patch_password(token, password, confirmation = password)
    patch password_reset_path(token), params: {
      email: @user.email,
      user: { password: password, password_confirmation: confirmation }
    }
  end

  test "登録していないメールアドレスでも同じメッセージで、メールは送られない" do
    post password_resets_path, params: { email: "nobody@example.com" }
    assert_redirected_to login_path
    assert_equal MESSAGE, flash[:notice]
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "未有効化のユーザーにはメールを送らない" do
    @user.update_column(:activated, false)
    post password_resets_path, params: { email: @user.email }
    assert_redirected_to login_path
    assert_equal MESSAGE, flash[:notice]
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "パスワードを再設定できる" do
    post password_resets_path, params: { email: @user.email }
    assert_redirected_to login_path
    assert_equal MESSAGE, flash[:notice]
    assert_equal 1, ActionMailer::Base.deliveries.size
    token=token_from(ActionMailer::Base.deliveries.last)

    # 間違ったトークン・違うメールアドレスではひらけない
    get edit_password_reset_path("invalid", email: @user.email)
    assert_redirected_to new_password_reset_path
    get edit_password_reset_path(token, email: "wrong@example.com")
    assert_redirected_to new_password_reset_path

    # 正しいリンクなら入力画面が開く
    get edit_password_reset_path(token, email: @user.email)
    assert_response :success

    # 空欄・短すぎる・確認用と違う、は保存できない
    patch_password(token, "")
    assert_response :unprocessable_entity
    patch_password(token, "a")
    assert_response :unprocessable_entity
    patch_password(token, "newpass", "different")
    assert_response :unprocessable_entity

    # 正しく入力すると、保存してログインできる
    patch_password(token, "newpass")
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
    assert @user.reload.authenticate("newpass")
    assert_nil @user.reset_digest

    # 同じリンクはもう使えない
    delete logout_path
    get edit_password_reset_path(token, email: @user.email)
    assert_redirected_to new_password_reset_path
  end

  test "期限切れのリンクは使えない" do
    post password_resets_path, params: { email: @user.email }
    token=token_from(ActionMailer::Base.deliveries.last)
    @user.update_column(:reset_sent_at, 3.hours.ago)

    get edit_password_reset_path(token, email: @user.email)
    assert_redirected_to new_password_reset_path

    patch_password(token, "newpass")
    assert_redirected_to new_password_reset_path
    assert_not @user.reload.authenticate("newpass")
  end
end
