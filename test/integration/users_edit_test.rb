require "test_helper"

class UsersEditTest < ActionDispatch::IntegrationTest
  def setup
    @user=create_activated_user("Hanako", "hanako@example.com")
    @other=create_activated_user("Taro", "taro@example.com")
  end

  def create_activated_user(name, email)
    user=User.create!(name: name, email: email, password: "foobar")
    user.update_columns(activated: true, activated_at: Time.zone.now)
    user
  end

  test "ログインしていないと編集画面を開けない" do
    get edit_user_path(@user)
    assert_redirected_to login_path
  end

  test "ログインしていないと更新できない" do
    patch user_path(@user), params: { user: { name: "Changed" } }
    assert_redirected_to login_path
    assert_equal "Hanako", @user.reload.name
  end

  test "他人の編集画面を開けない" do
    log_in_as(@user)
    get edit_user_path(@other)
    assert_redirected_to root_path
  end

  test "他人の名前を更新できない" do
    log_in_as(@user)
    patch user_path(@other), params: { user: { name: "Changed" } }
    assert_redirected_to root_path
    assert_equal "Taro", @other.reload.name
  end

  test "存在しないユーザーの編集画面を開けない" do
    log_in_as(@user)
    get edit_user_path(id: 0)
    assert_redirected_to root_path
  end

  test "名前以外の項目は変更できない" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { name: "Hanako", email: "hacked@example.com", activated: false } }
    @user.reload
    assert_equal "hanako@example.com", @user.email
    assert @user.activated?
  end

  test "名前が空欄・長すぎると更新できない" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { name: "a" * 51 } }
    assert_response :unprocessable_entity

    patch user_path(@user), params: { user: { name: "" } }
    assert_response :unprocessable_entity

    assert_equal "Hanako", @user.reload.name
  end

  test "本人は名前を変更できる" do
    log_in_as(@user)
    patch user_path(@user), params: { user: { name: "Changed" } }
    assert_redirected_to edit_user_path(@user)
    assert_equal "Changed", @user.reload.name
  end
end
