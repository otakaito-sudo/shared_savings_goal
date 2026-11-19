require "test_helper"

class RateLimitTest < ActionDispatch::IntegrationTest
  setup do
    @user=create_activated_user("Rate", "rate@example.com")
    ActionMailer::Base.deliveries.clear
  end

  test "ログインは3分間に10回まで" do
    10.times do
      post login_path, params: { email: @user.email, password: "wrong" }
      assert_response :unprocessable_entity
    end
    # 11回目は正しいパスワードでも弾かれる
    post login_path, params: { email: @user.email, password: "foobar" }
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end

  test "時間が経てば再びログインできる" do
    10.times { post login_path, params: { email: @user.email, password: "wrong" } }
    travel 3.minutes + 1.second do
      post login_path, params: { email: @user.email, password: "foobar" }
      assert_redirected_to root_path
    end
  end

  test "パスワード再設定は同じメールアドレスへ15分に3回まで" do
    3.times { post password_resets_path, params: { email: @user.email } }
    assert_equal 3, ActionMailer::Base.deliveries.size

    post password_resets_path, params: { email: @user.email }
    assert_redirected_to new_password_reset_path
    assert_equal 3, ActionMailer::Base.deliveries.size
  end

  test "有効化メールの再送は5分に1回まで" do
    post users_path, params: { user: { name: "New", email: "new@example.com",
                                     password: "foobar", password_confirmation: "foobar" } }
    assert_equal 1, ActionMailer::Base.deliveries.size

    post login_path, params: { email: "new@example.com", password: "foobar" }
    assert_equal 1, ActionMailer::Base.deliveries.size

    travel 6.minutes do
      post login_path, params: { email: "new@example.com", password: "foobar" }
      assert_equal 2, ActionMailer::Base.deliveries.size
    end
  end

  test "パスワード再設定の制限はメールアドレスごと" do
    other_user=create_activated_user("Other", "other@example.com")

    3.times do
      post password_resets_path, params: { email: @user.email }
    end
    assert_equal 3, ActionMailer::Base.deliveries.size

    post password_resets_path, params: { email: other_user.email }
    assert_equal 4, ActionMailer::Base.deliveries.size
  end
end
