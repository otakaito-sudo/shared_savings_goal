class DepositsController < ApplicationController
  before_action :require_login

  def create
    goal=current_user.saving_goals.find(params[:saving_goal_id])
    deposit=goal.deposits.new(deposit_params.merge(member: current_user))

    if deposit.save!
      redirect_to goal, notice: "入金を申請しました"
    else
      redirect_to goal, alert: deposit.errors.full_message.to_sentence
    end
  end

  def confirm
    run { Deposits::Confirm.new(deposit: deposit, reviewer: current_user).call }
  end

  def reject
    run { Deposits::Reject.new(deposit: deposit, reviewer: current_user).call }
  end

  def remand
    run { Deposits::Remand.new(deposit: deposit, reviewer: current_user, comment: params[:review_comment]).call }
  end

  def resubmit
    run { Deposits::Resubmit.new(deposit: deposit, requester: current_user, request_amount: params[:request_amount]).call }
  end

  private

  def deposit
    @deposit ||= Deposit.find(params[:id])
  end

  def deposit_params
    params.expect(deposit: [ :request_amount ])
  end

  def run
    yield
    redirect_to deposit.saving_goal, notice: "処理しました"
  rescue Deposits::Base::ExceedsTarget
    redirect_to deposit.saving_goal, alert: "目標金額を超えるため確認できません"
  rescue Deposits::Base::NotPending
    redirect_to deposit.saving_goal, alert: "この申請は既に処理済みです"
  rescue Deposits::Base::NotAuthorized
    redirect_to deposit.saving_goal, alert: "操作する権限がありません"
  rescue Deposits::Remand::CommentRequired
    redirect_to deposit.saving_goal, alert: "差し戻し理由を入力してください"
  rescue ActiveRecord::StaleObjectError
    redirect_to deposit.saving_goal, alert: "他の操作と競合しました。やり直してください"
  end
end
