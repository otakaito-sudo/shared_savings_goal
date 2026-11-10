module SavingGoals
  class InvitationsController < ApplicationController
    before_action :require_login
    before_action :set_goal
    before_action :require_manager

    # 招待メールの大量送信を防ぐ（管理者ごとに1時間20通まで）　　　<- いるかな？？？
    rate_limit to: 20, within: 1.hour, only: :create,
               by: -> { current_user.id },
               with: -> { redirect_to @goal, alert: "招待の送信回数が多過ぎます。時間を置いて試してください" }

    def create
      email=params[:email].to_s.strip.downcase

      unless @goal.open?
        return redirect_to @goal, alert: "募集中で期限内の目標にだけ招待できます"
      end

      if @goal.memberships.joins(:user).exists?(users: { email: email })
        return redirect_to @goal, alert: "その人はすでに参加しています"
      end

      invitation=@goal.invitations.new(invited_by: current_user, email: email)
      unless invitation.valid?
        return redirect_to @goal, alert: invitation.errors.full_messages.to_sentence
      end

      @goal.with_lock do
        # 同じ相手への未使用の招待を取り消し、最新のリンクだけ有効にする
        @goal.invitations.where(email: invitation.email, accepted_at: nil, revoked_at: nil)
                         .update_all(revoked_at: Time.current, updated_at: Time.current)
        invitation.save!
      end

      # 生のトークンはメモリ上にしかないのでdeliver_nowで送る
      InvitationMailer.invite(invitation).deliver_now
      redirect_to @goal, notice: "#{invitation.email} に招待メールを送りました"
    end
    def destroy
      # 自分が管理する目標の招待だけをさがす（他の目標の招待IDは見つからない）
      invitation=@goal.invitations.find(params[:id])

      invitation.with_lock do
        if invitation.active?
          invitation.update!(revoked_at: Time.current)
        end
      end

      if invitation.revoked_at.present? && invitation.accepted_at.nil?
        redirect_to @goal, notice: "#{invitation.email}への招待を取り消しました"
      else
        redirect_to @goal, alert: "この招待はすでに承諾済み、または無効です"
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
end
