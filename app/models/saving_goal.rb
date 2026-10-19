class SavingGoal < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :deposits, dependent: :destroy

  enum :status, { recruiting: 0, achieved: 1, canceled: 2 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :target_amount, numericality: { only_integer: true, greater_than: 0 }
  validates :deadline, presence: true
  validate  :deadline_cannnot_be_past, on: :create

  def current_amount
    deposits.confirmed.sum(:request_amount)
  end

  def remaining_amount
    target_amount - current_amount
  end

  def accepting_deposits?
    recruiting?
  end

  private

  def deadline_cannnot_be_past
    return if deadline.blank?
    errors.add(:deadline, "は本日以降の日付にしてください") if deadline < Date.current
  end
end
