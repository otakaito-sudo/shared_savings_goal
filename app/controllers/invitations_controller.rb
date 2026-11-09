class InvitationsController < ApplicationController
  before_action :protect_invitation_response
  before_action :require_login
  before_action :set_invitation

  def show
    return invalid_invitation unless usable_invitation?

    if @goal.memberships.exists?(user_id: current_user.id)
      redirect_to @goal, notice: "すでにこの目標に参加しています"
    end
  end

  def accept
    result = :invalid

    # 同じ目標への承諾処理を順番に行う
    @goal.with_lock do
      # 取り消しや別の承諾による変更を読み直してから確認する
      @invitation.lock!

      if !usable_invitation?
        result = :invalid
      elsif @goal.memberships.exists?(user_id: current_user.id)
        result = :already_member
      else
        @goal.memberships.create!(user: current_user, role: :member)
        @invitation.update!(accepted_at: Time.current)
        result= :accepted
      end
    end

    case result
    when :accepted
      redirect_to @goal, notice: "招待を承諾し、目標に参加しました"
    when :already_member
      redirect_to @goal, notice: "すでにこの目標に参加しています"
    else
      invalid_invitation
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # 別の処理と同時に参加しようとした場合などは、安全に失敗させる
    redirect_to root_path, alert: "参加できませんでした。状態を確認してください"
  end

  private

  def protect_invitation_response
    response.headers["Referrer-Policy"]="no-referrer"
    response.headers["Cache-Control"]="no-store"
  end

  def set_invitation
    @invitation=Invitation.find_by(id: params[:id])
    return invalid_invitation unless @invitation

    @goal=@invitation.saving_goal
  end

  def usable_invitation?
    token = params[:token]

    token.is_a?(String) &&
    current_user.activated? &&
    current_user.email==@invitation.email &&
    @invitation.active? &&
    @invitation.authenticated?(token) &&
    @goal.open?
  end

  def invalid_invitation
    redirect_to root_path, alert: "招待を利用できません。ログイン中のアカウントや招待の状態を確認してください"
  end
end
