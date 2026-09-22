class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?

    case current_user.role
    when "admin"
      @recent_submissions = ChecklistSubmission.for_company.recent.limit(5)
      @templates_count = ChecklistTemplate.count
      render :admin
    when "chofer"
      @assignment = current_user.active_assignment
      @vehicle    = @assignment&.vehicle
      @documents  = @vehicle&.vehicle_documents&.order(:due_on) || []
      @my_submissions = ChecklistSubmission.for_chofer(current_user).recent.limit(3)
      render :chofer
    when "mecanico"   then render :mecanico
    when "analista"   then render :analista
    when "superadmin" then render :superadmin
    else
      redirect_to root_path, alert: "Rol no definido."
    end
  end
end
