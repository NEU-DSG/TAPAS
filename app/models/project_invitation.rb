# frozen_string_literal: true

class ProjectInvitation < ApplicationRecord
  belongs_to :project
  belongs_to :creator, class_name: "User", foreign_key: :created_by_user_id

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  validates :token, presence: true, uniqueness: true
  validates :project, presence: true
  validates :creator, presence: true

  scope :active,  -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where(revoked_at: nil).where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def usable?
    !expired? && !revoked?
  end

  private

  def generate_token
    return if token.present?
    self.token = loop do
      candidate = SecureRandom.urlsafe_base64(32)
      break candidate unless ProjectInvitation.exists?(token: candidate)
    end
  end

  def set_expires_at
    self.expires_at ||= 90.days.from_now
  end
end
