class ChecklistTemplate < ApplicationRecord
  belongs_to :company

  default_scope { where(company: Current.company) }

  before_validation :assign_company

  has_paper_trail

  has_many :checklist_items, -> { order(:position) }, dependent: :destroy
  has_many :checklist_submissions, dependent: :destroy

  validates :name, presence: true

  accepts_nested_attributes_for :checklist_items,
    allow_destroy: true,
    reject_if: :all_blank

  private

  def assign_company
    self.company ||= Current.company
  end
end
