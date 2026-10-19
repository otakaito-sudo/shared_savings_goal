class Deposit < ApplicationRecord
  belongs_to :saving_goal
  belongs_to :member, class_name: "User"
  belongs_to :reviewer, class_name: "User",
             foreign_key: :reviewed_by_id, optional: true

  enum :status, { pending: 0, confirmed: 1, rejected: 2, remanded: 3 }

  validates :request_amount,
            numericality: { only_integer: true, greater_than: 0 }
  validate :member_must_participate
  validate :goal_must_accept_deposits, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def reviewed?
    reviewed_at.present?
  end

  def membership
    Membership.find_by(saving_goal_id: saving_goal_id, user_id: member_id)
  end

  private

  def member_must_participate
    return if saving_goal_id.blank? || member_id.blank?
    return if Membership.exists?(saving_goal_id: saving_goal_id, user_id: member_id)
    errors.add(:member, "はこの貯金目標に参加していません")
  end

  def goal_must_accept_deposits
    return if saving_goal.blank?
    return if saving_goal.recruiting?
    errors.add(:base, "達成・中止した目標には入金申請できません")
  end
end
