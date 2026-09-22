class Expense < ApplicationRecord
  belongs_to :company
  belongs_to :vehicle, optional: true
  belongs_to :source, polymorphic: true, optional: true

  has_many_attached :documents

  enum category: { maintenance: 0, fuel: 1, parts: 2, tolls: 3, insurance: 4, other: 5 }

  default_scope { where(company: Current.company) }
  before_validation :assign_company

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :date, presence: true
  validates :currency, inclusion: { in: %w[CLP USD] }

  private

  def assign_company
    self.company ||= Current.company
  end
end
