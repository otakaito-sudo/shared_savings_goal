class MembershipsController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :require_manager

  def create
    user=User.find_by(email: params[:email].to_s.strip.downcase)
    return redirect_to @goal, alert: "そのメールアドレスのユーザーが見つかりません" if user.nil?

    membership = @goal.memberships.new(user: user, role: params[:role].presence || "member")

    if membership.save
      redirect_to @goal, notice: "#{user.name} さんを追加しました"
    else
      redirect_to @goal, alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership=@goal.memberships.find(params[:id])

    if membership.destroy
      redirect_to @goal, notice: "#{membership.user.name} さんを外しました"
    else
      redirect_to @goal, alert: membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_goal
    @goal=current_user.saving_goals.find(params[:saving_goal_id])
  end

  def require_manager
    return if @goal.memberships.find_by(user: current_user)&.manager?
    redirect_to @goal, alert: "メンバーを管理する権限がありません"
  end
end
