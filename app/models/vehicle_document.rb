class VehicleDocument < ApplicationRecord
  has_paper_trail

  belongs_to :vehicle
  has_one_attached :file
  has_many :notifications, as: :notifiable, dependent: :destroy

  enum :doc_type, {
    permiso_circulacion: 0,
    revision_tecnica: 1,
    seguro: 2,
    padron: 3,
    otro: 4
  }

  enum :status, { ok: 0, expiring: 1, expired: 2 }

  validates :doc_type, presence: true
  validates :due_on, presence: true
  validates :file, presence: { message: "debe adjuntar un archivo PDF" }
  validate :file_must_be_pdf, if: -> { file.attached? }

  private

  def file_must_be_pdf
    unless file.content_type == "application/pdf"
      errors.add(:file, "debe ser un archivo PDF")
    end
  end
end
