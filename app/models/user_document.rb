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

  has_many :notifications, as: :notifiable, dependent: :destroy
end
