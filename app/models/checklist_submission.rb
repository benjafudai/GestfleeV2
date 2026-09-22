class ChecklistSubmission < ApplicationRecord
  include CompanyScoped
  include VehicleAssignable
  vehicle_assignable_actor :user

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
  validate :photos_must_be_images

  before_validation :set_submitted_at, on: :create

  scope :for_chofer, ->(user) { where(user: user) }

  scope :recent, -> { order(submitted_at: :desc) }

  private

  # Sobreescribe el assign_company de CompanyScoped: la empresa de un checklist
  # es la del vehículo, con Current.company solo como respaldo.
  def assign_company
    self.company ||= vehicle&.company || Current.company
  end

  def only_one_submission_per_day
    if user_id.present? && ChecklistSubmission.where(user_id: user_id, submitted_at: Time.current.all_day).exists?
      errors.add(:base, "Ya has completado tu checklist del día de hoy.")
    end
  end

  def photos_must_be_images
    photos.each do |photo|
      next if photo.content_type.to_s.start_with?("image/")
      errors.add(:photos, "debe ser una imagen (jpg, png, etc.)")
    end
  end

  def set_submitted_at
    self.submitted_at ||= Time.current
  end
end
