class Part < ApplicationRecord
  belongs_to :company
  has_many :part_fitments, dependent: :destroy
  has_many :vehicles, through: :part_fitments

  default_scope { where(company: Current.company) }

  before_validation :assign_company

  validates :sku, :name, :unit_of_measure, presence: true
  validates :sku, uniqueness: { scope: :company_id }
  validates :currency, inclusion: { in: %w[CLP USD] }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }

  private

  def assign_company
    self.company ||= Current.company
  end
end
