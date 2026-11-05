class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    if (user_id=session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    elsif (user_id=cookies.encrypted[:user_id])
      user=User.find_by(id: user_id)
      if user&.authenticated?(:remember, cookies.encrypted[:remember_token])
        reset_session
        session[:user_id]=user.id
        @current_user=user
      end
    end
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    redirect_to login_path, alert: "ログインしてください" unless logged_in?
  end

  def require_logout
    redirect_to root_path, notice: "すでにログインしています" if logged_in?
  end

  # ログイン状態を保持する
  def remember(user)
    user.remember
    cookies.encrypted[:user_id]=remember_cookie(user.id)
    cookies.encrypted[:remember_token]=remember_cookie(user.remember_token)
  end

  # ログイン状態の保持をやめる
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # ログアウトする
  def log_out
    forget(current_user)
    reset_session
    @current_user=nil
  end

  def remember_cookie(value)
    {
      value: value,
      expires: 30.days,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end
end
