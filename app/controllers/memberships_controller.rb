class MembershipsController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :require_manager

  def destroy
    membership=@goal.memberships.find(params[:id])

    @goal.with_lock do
      # 金額編集・招待承諾と同じ目標ロックを使い、配分の整合性を守る。
      membership.reload
      unless @goal.memberships.find_by(user: current_user)&.manager?
        raise ActiveRecord::RecordNotFound
      end
      membership.destroy!
      @goal.activities.create!(actor: current_user, kind: :member_removed, target_user: membership.user)
    end
      redirect_to @goal, notice: "#{membership.user.name} さんを外しました"
  rescue ActiveRecord::RecordNotDestroyed
      redirect_to @goal, alert: membership.errors.full_messages.to_sentence
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
