class Membership < ApplicationRecord
  belongs_to :saving_goal
  belongs_to :user

  has_many :deposits,
           foreign_key: [ :saving_goal_id, :member_id ],
           primary_key: [ :saving_goal_id, :user_id ],
           dependent: :restrict_with_error

  enum :role, { member: 0, manager: 1 }

  validates :user_id, uniqueness: { scope: :saving_goal_id,
                                    message: "は既にこの目標に参加しています" }
end
