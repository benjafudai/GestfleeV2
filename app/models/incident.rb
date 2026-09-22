class Incident < ApplicationRecord
  include CompanyScoped
  include VehicleAssignable
  vehicle_assignable_actor :reporter

  belongs_to :vehicle
  belongs_to :reporter, class_name: 'User'

  has_many_attached :photos
  has_paper_trail

  enum status: { pending: 0, in_review: 1, resolved: 2 }
  enum severity: { low: 0, medium: 1, high: 2, critical: 3 }

  after_initialize :set_defaults, if: :new_record?

  validates :description, presence: true
  validate :photos_must_be_images

  private

  def set_defaults
    self.status ||= :pending
    self.severity ||= :low
  end

  def photos_must_be_images
    photos.each do |photo|
      next if photo.content_type.to_s.start_with?("image/")
      errors.add(:photos, "debe ser una imagen (jpg, png, etc.)")
    end
  end
end
