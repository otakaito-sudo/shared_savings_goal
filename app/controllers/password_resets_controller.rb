class PasswordResetsController < ApplicationController
  before_action :require_logout
  before_action :get_user, only: [ :edit, :update ]
  before_action :valid_user, only: [ :edit, :update ]
  before_action :check_expiration, only: [ :edit, :update ]
  def new
  end

  def create
    user=User.find_by(email: params[:email])
    if user&.activated?
      user.create_reset_digest
      user.send_password_reset_email
    end
    redirect_to login_path, notice: "入力されたメールアドレスが登録されている場合、再設定メールを送信しました"
  end

  def edit
  end

  def update
    if params.dig(:user, :password).blank?
      @user.errors.add(:password, "を入力してください")
      render :edit, status: :unprocessable_entity
    elsif @user.update(user_params)
      @user.update_column(:reset_digest, nil)
      reset_session
      session[:user_id]=@user.id
      redirect_to root_path, notice: "パスワードを再設定しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :password, :password_confirmation ])
  end

  def get_user
    @user=User.find_by(email: params[:email].to_s.strip.downcase)
  end

  def valid_user
    unless @user&.activated? && @user.authenticated?(:reset, params[:id])
      redirect_to new_password_reset_path, alert: "無効なリンクです"
    end
  end

  def check_expiration
    if @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: "リンクの有効期限が切れています。もう一度お試しください"
    end
  end
end
