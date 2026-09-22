class ChecklistSubmission < ApplicationRecord
  belongs_to :checklist_template
  belongs_to :vehicle
  belongs_to :user   # el chofer que lo completó

  has_many_attached :photos

  has_many :checklist_answers, dependent: :destroy
  accepts_nested_attributes_for :checklist_answers

  has_paper_trail

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :vehicle, :user, :checklist_template, presence: true
  validates :submitted_at, presence: true
  validate :only_one_submission_per_day, on: :create

  before_validation :set_submitted_at, on: :create

  scope :for_company, -> {
    joins(:vehicle).where(vehicles: { company: Current.company })
  }

  scope :for_chofer, ->(user) { where(user: user) }

  scope :recent, -> { order(submitted_at: :desc) }

  private

  def only_one_submission_per_day
    if user_id.present? && ChecklistSubmission.where(user_id: user_id, submitted_at: Time.current.all_day).exists?
      errors.add(:base, "Ya has completado tu checklist del día de hoy.")
    end
  end

  def set_submitted_at
    self.submitted_at ||= Time.current
  end
end
