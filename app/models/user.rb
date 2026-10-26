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

  attr_accessor :activation_token
  before_create :create_activation_digest

  # 文字列をハッシュ化する
  def self.digest(string)
    cost=ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def authenticated?(attribute, token)
    digest=send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  private

  def create_activation_digest
    self.activation_token=User.new_token
    self.activation_digest=User.digest(activation_token)
  end
end
