class UserDocument < ApplicationRecord
  has_paper_trail

  belongs_to :user
  has_one_attached :file

  enum doc_type: {
    licencia_conducir: 0,
    carnet_identidad: 1,
    examen_preocupacional: 2,
    contrato: 3,
    otro: 4
  }

  enum status: { ok: 0, expiring: 1, expired: 2 }

  validates :doc_type, presence: true
  validates :due_on, presence: true
  validates :file, presence: { message: "debe adjuntar un archivo" }
  validate :file_must_be_image_or_pdf, if: -> { file.attached? }

  has_many :notifications, as: :notifiable, dependent: :destroy

  private

  def file_must_be_image_or_pdf
    content_type = file.content_type.to_s
    return if content_type.start_with?("image/") || content_type == "application/pdf"

    errors.add(:file, "debe ser una imagen o un PDF")
  end
end
