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
      @month_expenses = policy_scope(Expense).where(date: Date.current.all_month)
      # Los gastos en USD se convierten a CLP antes de sumar (igual que en Costos).
      @expenses_by_category = Hash.new(0)
      @month_expenses.group(:category, :currency).sum(:amount).each do |(category, currency), amount|
        @expenses_by_category[category] += amount_in_clp(amount, currency)
      end
      @total_month_cost = @expenses_by_category.values.sum
      @fuel_month_cost = @expenses_by_category["fuel"]
      @maintenance_month_cost = @expenses_by_category["maintenance"]
      @pending_supply_requests_count = SupplyRequest.joins(:vehicle).where.not(status: :delivered).count
      render :analista
    when "bodeguero"
      @total_parts = Part.count
      @low_stock_parts = Part.where("stock <= ?", 5).order(:stock)
      # Repuestos con costo en USD se valorizan en CLP (igual que en el catálogo de repuestos).
      @total_stock_value = Part.group(:currency).sum(Arel.sql("stock * cost"))
                               .sum { |currency, value| amount_in_clp(value, currency) }
      @pending_supply_requests = SupplyRequest.joins(:vehicle).where.not(status: :delivered).order(created_at: :desc)
      @recent_supply_requests = SupplyRequest.joins(:vehicle).order(created_at: :desc).limit(5)
      render :bodeguero
    when "superadmin"
      @companies_count = Company.count
      @users_count = User.count
      @companies_without_admin = Company.where.not(id: User.where(role: :admin).select(:company_id))
      render :superadmin
    else
      # root_path is this same action, so redirecting there would loop forever
      sign_out current_user
      redirect_to new_user_session_path, alert: "Rol no definido."
    end
  end

  private

  def amount_in_clp(amount, currency)
    currency == "USD" ? amount.to_d * CurrencyConverter.usd_to_clp.to_d : amount.to_d
  end
end
