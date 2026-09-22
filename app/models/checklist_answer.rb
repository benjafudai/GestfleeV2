class ChecklistAnswer < ApplicationRecord
  belongs_to :checklist_submission
  belongs_to :checklist_item

  validates :checklist_item, presence: true
  validate :value_required_if_item_required

  private

  def value_required_if_item_required
    if checklist_item&.required? && value.blank?
      errors.add(:value, "es obligatorio para el ítem \"#{checklist_item.label}\"")
    end
  end
end
