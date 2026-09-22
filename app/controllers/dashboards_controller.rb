class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?

    case current_user.role
    when "admin"
      # ChecklistSubmission ya se filtra por empresa automáticamente (default_scope).
      @recent_submissions = ChecklistSubmission.recent.includes(:checklist_template, :vehicle, :user).limit(5)
      @templates_count = ChecklistTemplate.count
      render :admin
    when "chofer"
      @assignment = current_user.active_assignment
      @vehicle    = @assignment&.vehicle
      @documents  = @vehicle&.vehicle_documents&.with_attached_file&.order(:due_on) || []
      @my_submissions = ChecklistSubmission.for_chofer(current_user).recent.includes(:checklist_template).limit(3)
      render :chofer
    when "mecanico"   then render :mecanico
    when "analista"   then render :analista
    when "superadmin" then render :superadmin
    else
      redirect_to root_path, alert: "Rol no definido."
    end
  end
end
