class SavingGoalsController < ApplicationController
  before_action :require_login        # ログイン必須

  def index
    @pagy, @goals = pagy(:offset,
      current_user.saving_goals.includes(:creator).order(deadline: :asc, id: :asc))   # includeは作成者を先読みして、n+1問題を防ぐ
  end

  def show
    @goal=current_user.saving_goals.find(params[:id])
    @membership=@goal.memberships.find_by(user: current_user)
    if @membership&.manager?
      @pending_invitations=@goal.invitations.pending.order(created_at: :desc)
    end
    @deposit_pagy, @deposits=pagy(:offset,
      @goal.deposits.includes(:member, :reviewer).recent,
      limit: 10, page_key: "deposits_page")
    @deposit=Deposit.new
    @activities=@goal.activities.includes(:actor, :target_user).recent.limit(5)

    @my_remanded_deposits = @goal.deposits.where(member: current_user, status: :remanded).recent
    @pending_deposit_count = @membership&.manager? ? @goal.deposits.pending.count : 0
    @member_totals = @goal.deposits.confirmed.group(:member_id).sum(:request_amount)
  end

  def new
    @goal=SavingGoal.new
  end

  def create
    @goal=SavingGoal.new(goal_params.merge(creator: current_user))
    ActiveRecord::Base.transaction do
      @goal.save!
      @goal.memberships.create!(user: current_user, role: :manager)
    end
    redirect_to @goal, notice: "貯金目標を作成しました"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  private

  def goal_params
    params.expect(saving_goal: [ :name, :purpose, :target_amount, :deadline ])
  end
end
