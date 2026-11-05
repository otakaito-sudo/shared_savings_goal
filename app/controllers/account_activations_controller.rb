class AccountActivationsController < ApplicationController
  def edit
    user=User.find_by(email: params[:email])

    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      if user.activation_expired?
        redirect_to login_path, alert: "有効化リンクの期限が切れています。ログインすると、新しい確認メールを送ります"
      else
        user.update_columns(activated: true, activated_at: Time.zone.now)
        reset_session
        session[:user_id]=user.id
        flash[:success]="アカウント有効化できました！"
        redirect_to root_url
      end
    else
      flash[:danger]="無効なリンクです"
      redirect_to root_url
    end
  end
end
