class AlertsController < ApplicationController
  def index
    authorize :alert, :index?
    
    company = current_user.company
    if current_user.superadmin? && company.blank?
      @vehicle_documents = VehicleDocument.where(status: [:expiring, :expired]).order(:due_on)
      @user_documents = UserDocument.where(status: [:expiring, :expired]).order(:due_on)
    else
      @vehicle_documents = VehicleDocument.joins(:vehicle).where(vehicles: { company_id: company.id }, status: [:expiring, :expired]).order(:due_on)
      @user_documents = UserDocument.joins(:user).where(users: { company_id: company.id }, status: [:expiring, :expired]).order(:due_on)
    end
  end
end
