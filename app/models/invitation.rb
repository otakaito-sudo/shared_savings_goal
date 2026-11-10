class Invitation < ApplicationRecord
  belongs_to :saving_goal
  belongs_to :invited_by, class_name: "User"

  attr_accessor :token

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, length: { maximum: 255 },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_digest, presence: true
  validates :expires_at, presence: true

  before_validation :prepare_token, on: :create

  scope :pending, -> {
    where(accepted_at: nil, revoked_at: nil).where("expires_at > ?", Time.current)
  }

  def authenticated?(given_token)
    return false if token_digest.blank? || given_token.blank?

    BCrypt::Password.new(token_digest).is_password?(given_token)
  end

  def expired?
    expires_at.nil? || expires_at <= Time.current
  end

  def active?
    accepted_at.nil? && revoked_at.nil? && !expired?
  end

  private

  def prepare_token
    if token_digest.blank?
      self.token=User.new_token
      self.token_digest=User.digest(token)
    end

    self.expires_at ||=7.days.from_now
  end
end
