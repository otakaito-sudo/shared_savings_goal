class Membership < ApplicationRecord
  belongs_to :saving_goal
  belongs_to :user

  has_many :deposits,
           foreign_key: [ :saving_goal_id, :member_id ],
           primary_key: [ :saving_goal_id, :user_id ],
           dependent: :restrict_with_error

  enum :role, { member: 0, manager: 1 }, validate: true

  validates :user_id, uniqueness: { scope: :saving_goal_id,
                                    message: "は既にこの目標に参加しています" }

  before_destroy :ensure_another_manager_remains

  private

  def ensure_another_manager_remains
    return if destroyed_by_association
    return unless manager?
    return if saving_goal.memberships.manager.where.not(id: id).exists?

    errors.add(:base, "最後の管理者は外せません")
    throw :abort
  end
end
