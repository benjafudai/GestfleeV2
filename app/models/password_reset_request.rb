class PasswordResetRequest < ApplicationRecord
  belongs_to :user
  belongs_to :admin, class_name: 'User', optional: true

  enum status: { pending: 0, approved: 1, rejected: 2, completed: 3 }

  validates :status, presence: true
end
