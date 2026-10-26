class UsersController < ApplicationController
  def new
    @user=User.new
  end

  def create
    @user=User.new(params.expect(user: [ :name, :email, :password ]))
    if @user.save
      session[:user_id]=@user.id
      redirect_to root_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
