class TargetAmountsController < ApplicationController
  before_action :require_login
  before_action :set_goal
  before_action :require_manager

  def edit
    prepare_form
  end

  def update
    @form_errors = []
    @submitted_total = params[:target_amount]
    @submitted_members = params[:member_targets].is_a?(ActionController::Parameters) ? params[:member_targets] : ActionController::Parameters.new
    saved = false

    # 入金承認・招待承諾・メンバー削除と同じ目標をロックする。
    @goal.with_lock do
      raise ActiveRecord::RecordNotFound unless @goal.memberships.find_by(user: current_user)&.manager?
      @memberships = @goal.memberships.includes(:user).order(:id).to_a
      total = parse_amount(@submitted_total, minimum: 1)
      values = {}
      expected_ids = @memberships.map { |membership| membership.id.to_s }.sort
      if @submitted_members.keys.sort != expected_ids
        @form_errors << "メンバーが変更されました。画面を開き直して入力してください。"
      end
      @form_errors << "全体目標は1円以上1億円以下の整数で入力してください。" unless total
      @memberships.each do |membership|
        amount = parse_amount(@submitted_members[membership.id.to_s], minimum: 0)
        if amount.nil?
          @form_errors << "#{membership.user.name}さんの目標は0円以上1億円以下の整数で入力してください。"
        else
          values[membership.id] = amount
        end
      end
      if total && values.size == @memberships.size && values.values.sum != total
        @form_errors << "個人目標の合計と全体目標を一致させてください。"
      end
      @form_errors << "達成・中止した目標は編集できません。" unless @goal.recruiting?
      if total && total <= @goal.current_amount
        @form_errors << "全体目標は確認済みの入金額より大きくしてください。"
      end

      if @form_errors.empty?
        @goal.update!(target_amount: total)
        @memberships.each { |membership| membership.update!(target_amount: values.fetch(membership.id)) }
        saved = true
      end
    end

    if saved
      redirect_to @goal, notice: "目標金額を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_goal
    @goal = current_user.saving_goals.find(params[:saving_goal_id])
  end

  def require_manager
    return if @goal.memberships.find_by(user: current_user)&.manager?
    redirect_to @goal, alert: "目標金額を編集する権限がありません"
  end

  def prepare_form
    @memberships = @goal.memberships.includes(:user).order(:id).to_a
    @form_errors = []
  end

  def parse_amount(value, minimum:)
    return unless value.is_a?(String) && value.match?(/\A[0-9]+\z/)
    number = value.to_i
    number if number.between?(minimum, 100_000_000)
  end
end
