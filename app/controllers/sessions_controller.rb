class SessionsController < ApplicationController
  def new; end

  def create
    user=User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      session[:user_id]=user.id
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert]="メールアドレスまたはパスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "ログアウトしました"
  end
end
