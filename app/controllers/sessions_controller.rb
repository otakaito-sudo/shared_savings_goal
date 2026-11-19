class SessionsController < ApplicationController
  before_action :require_logout, only: [ :new, :create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "ログインの試行回数が多過ぎます。しばらくしてからお試しください" }
  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      if user.activated?
        reset_session
        session[:user_id] = user.id
        params[:remember_me] == "1" ? remember(user) : forget(user)
        redirect_to root_path, notice: "ログインしました"
      elsif user.resend_activation_email
        redirect_to login_path, alert: "アカウントが有効化されていません。確認メールを再送したので、リンクから有効化してください"
      else
        redirect_to login_path, alert: "アカウントが有効化されていません。送信済みの確認メールのリンクから有効化してください"
      end
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to login_path, notice: "ログアウトしました"
  end
end
