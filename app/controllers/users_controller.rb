class UsersController < ApplicationController
  before_action :require_logout, only: [ :new, :create ]
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
end
