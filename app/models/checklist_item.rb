class ChecklistItem < ApplicationRecord
  belongs_to :checklist_template
  has_many :checklist_answers, dependent: :destroy

  enum :item_type, { boolean: 0, text: 1, number: 2 }

  validates :label, presence: true
  validates :item_type, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  default_scope { order(:position) }
end
