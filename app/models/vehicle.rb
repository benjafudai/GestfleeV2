class Vehicle < ApplicationRecord
  belongs_to :company
  
  default_scope { where(company: Current.company) }
  
  before_validation :assign_company

  private

  def assign_company
    self.company ||= Current.company
  end

  public
  
  has_paper_trail

  has_many :vehicle_documents, dependent: :destroy
  has_many :vehicle_assignments, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: 'VehicleAssignment'
  has_many :checklist_submissions, dependent: :destroy
  has_many :incidents, dependent: :destroy
  has_many :roadside_assistance_events, dependent: :destroy

  enum status: { active: 0, maintenance: 1, inactive: 2 }

  validates :plate, presence: true, uniqueness: true
  validates :year, numericality: { allow_nil: true, greater_than: 1950 }
end
