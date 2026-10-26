class AccountActivationsController < ApplicationController
  def edit
    user=User.find_by(email: params[:email])

    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.update_attribute(:activated, true)
      user.update_attribute(:activated_at, Time.zone.now)
      login user
      flash[:success]="アカウント有効化できました！"
      redirect_to root_url
    else
      flash[:danger]="無効なリンクです"
      redirect_to root_url
    end
  end
end
