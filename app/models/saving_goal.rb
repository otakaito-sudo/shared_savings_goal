class SavingGoal < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :deposits, dependent: :destroy
  has_many :invitations, dependent: :destroy

  enum :status, { recruiting: 0, achieved: 1, canceled: 2 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :target_amount, numericality: { only_integer: true, greater_than: 0, message: "は0より大きい値にしてください" }
  validates :target_amount, numericality: { less_than_or_equal_to: 100_000_000, message: "1億円以下にしてください" }
  validates :deadline, presence: true
  validate  :deadline_cannnot_be_past, on: :create

  def current_amount
    deposits.confirmed.sum(:request_amount)
  end

  def remaining_amount
    target_amount - current_amount
  end

  def deadline_passed?
    deadline.present? && deadline < Date.current
  end

  # 募集中かつ期限内=新しい参加・入金を受け付ける状態
  def open?
    recruiting? && !deadline_passed?
  end

  def accepting_deposits?
    open?
  end

  # 画面表示用の状態(DBのstatusは買えない)
  def display_status
    return :expired if recruiting? && deadline_passed?
    status.to_sym
  end

  private

  def deadline_cannnot_be_past
    return if deadline.blank?
    errors.add(:deadline, "は本日以降の日付にしてください") if deadline < Date.current
  end
end
