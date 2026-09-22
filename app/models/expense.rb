class Expense < ApplicationRecord
  include CompanyScoped

  belongs_to :vehicle, optional: true
  belongs_to :source, polymorphic: true, optional: true

  has_many_attached :documents

  enum category: { maintenance: 0, fuel: 1, parts: 2, tolls: 3, insurance: 4, other: 5 }

  CATEGORY_LABELS = {
    "maintenance" => "Mantenimiento",
    "fuel" => "Combustible",
    "parts" => "Repuestos",
    "tolls" => "Peajes",
    "insurance" => "Seguros",
    "other" => "Otros"
  }.freeze

  def self.human_category(category)
    CATEGORY_LABELS[category.to_s] || category.to_s.humanize
  end

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :date, presence: true
  validates :currency, inclusion: { in: %w[CLP USD] }
  validate :documents_must_be_image_or_pdf

  private

  def documents_must_be_image_or_pdf
    documents.each do |document|
      content_type = document.content_type.to_s
      next if content_type.start_with?("image/") || content_type == "application/pdf"

      errors.add(:documents, "debe ser una imagen o un PDF")
    end
  end
end
