class User < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :saving_goals, through: :memberships
  has_many :created_goals, class_name: "SavingGoal",
           foreign_key: :created_by_id, dependent: :restrict_with_error

  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: true
  validates :password, length: { minimum: 6 }, allow_nil: true
end
