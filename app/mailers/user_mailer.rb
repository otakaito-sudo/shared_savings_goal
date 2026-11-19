class UserMailer < ApplicationMailer
  def account_activation(user)
    @user=user
    mail to: @user.email, subject: "アカウントを有効化してください"
  end

  def password_reset(user)
    @user=user
    mail to: @user.email, subject: "パスワードを再設定してください"
  end
end
