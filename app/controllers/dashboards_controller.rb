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
    when "mecanico"
      @pending_work_orders = WorkOrder.where(status: :pending).order(created_at: :desc)
      @in_progress_work_orders = WorkOrder.where(status: :in_progress)
      @completed_this_month = WorkOrder.where(status: :completed).where(updated_at: Date.today.beginning_of_month..)
      @low_stock_parts = Part.where("stock <= ?", 5).order(:stock)
      @recent_work_orders = WorkOrder.order(created_at: :desc).limit(5)
      @pending_supply_requests = SupplyRequest.joins(:vehicle).where(user: current_user).where.not(status: :delivered).order(created_at: :desc).limit(5)
      render :mecanico
    when "analista"
      @month_expenses = Expense.where(date: Date.today.beginning_of_month..Date.today.end_of_month)
      @total_month_cost = @month_expenses.sum(:amount)
      @fuel_month_cost = @month_expenses.where(category: :fuel).sum(:amount)
      @maintenance_month_cost = @month_expenses.where(category: :maintenance).sum(:amount)
      @pending_supply_requests_count = SupplyRequest.joins(:vehicle).where.not(status: :delivered).count
      @expenses_by_category = @month_expenses.group(:category).sum(:amount)
      render :analista
    when "bodeguero"
      @total_parts = Part.count
      @low_stock_parts = Part.where("stock <= ?", 5).order(:stock)
      @total_stock_value = Part.sum("stock * cost")
      @pending_supply_requests = SupplyRequest.joins(:vehicle).where.not(status: :delivered).order(created_at: :desc)
      @recent_supply_requests = SupplyRequest.joins(:vehicle).order(created_at: :desc).limit(5)
      render :bodeguero
    when "superadmin"
      @companies_count = Company.count
      @users_count = User.count
      @companies_without_admin = Company.where.not(id: User.where(role: :admin).select(:company_id))
      render :superadmin
    else
      redirect_to root_path, alert: "Rol no definido."
    end
  end
end
