class MembershipsController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :require_manager

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
