class AlertsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :alert, :index?
    
    company = current_user.company
    if current_user.superadmin? && company.blank?
      @vehicle_documents = VehicleDocument.includes(:vehicle).where(status: [:expiring, :expired]).order(:due_on)
      @user_documents = UserDocument.includes(:user).where(status: [:expiring, :expired]).order(:due_on)
    else
      @vehicle_documents = VehicleDocument.includes(:vehicle).joins(:vehicle).where(vehicles: { company_id: company.id }, status: [:expiring, :expired]).order(:due_on)
      @user_documents = UserDocument.includes(:user).joins(:user).where(users: { company_id: company.id }, status: [:expiring, :expired]).order(:due_on)
    end
  end
end
