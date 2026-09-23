class ChecklistTemplate < ApplicationRecord
  include CompanyScoped

  has_paper_trail

  has_many :checklist_items, -> { order(:position) }, dependent: :destroy
  has_many :checklist_submissions, dependent: :destroy

  validates :name, presence: true

  accepts_nested_attributes_for :checklist_items,
    allow_destroy: true,
    reject_if: :all_blank
end
