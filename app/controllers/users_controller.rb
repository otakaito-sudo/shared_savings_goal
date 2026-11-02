class UsersController < ApplicationController
  before_action :require_logout, only: [ :new, :create ]
  before_action :require_login, only: [ :edit, :update ]
  before_action :correct_user, only: [ :edit, :update ]
  def new
    @user=User.new
  end

  def create
    @user=User.new(params.expect(user: [ :name, :email, :password ]))
    if @user.save
      @user.send_activation_email
      redirect_to login_path, notice: "確認メールを送信しました。メール内のリンクからアカウントを有効化してください"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(profile_params)
      redirect_to edit_user_path(@user), notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.expect(user: [ :name ])
  end

  def correct_user
    @user=User.find_by(id: params[:id])
    redirect_to root_path, alert: "このページにはアクセスできません" unless @user==current_user
  end
end
