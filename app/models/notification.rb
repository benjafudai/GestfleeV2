class Notification < ApplicationRecord
  belongs_to :user # recipient
  belongs_to :notifiable, polymorphic: true

  validates :title, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }

  def mark_as_read!
    update(read_at: Time.current)
  end

  def read?
    read_at.present?
  end
end
