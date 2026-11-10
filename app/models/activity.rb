class Activity < ApplicationRecord
  belongs_to :saving_goal
  belongs_to :actor, class_name: "User"
  belongs_to :target_user, class_name: "User", optional: :true
  belongs_to :deposit, optional: true

  enum :kind, {
    deposit_requested: 0,
    deposit_confirmed: 1,
    deposit_rejected: 2,
    deposit_remanded: 3,
    deposit_resubmitted: 4,
    member_joined: 5,
    member_removed: 6,
    goal_achieved: 7
  }

  validates :kind, presence: true
  scope :recent, -> { order(created_at: :desc, id: :desc) }
end
