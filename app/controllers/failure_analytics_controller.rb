class FailureAnalyticsController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize :failure_analytics, :index?

    @vehicles = current_user.superadmin? ? Vehicle.unscoped.order(:plate) : Vehicle.order(:plate)
    @vehicle = @vehicles.find_by(id: params[:vehicle_id]) if params[:vehicle_id].present?

    company_incidents = incidents_for_company
    incidents_scope = @vehicle ? company_incidents.where(vehicle_id: @vehicle.id) : company_incidents
    work_orders_scope = @vehicle ? WorkOrder.where(vehicle_id: @vehicle.id) : WorkOrder.all

    @total_incidents = incidents_scope.count
    @incidents_by_severity = incidents_scope.group(:severity).count

    @total_work_orders = work_orders_scope.count
    @total_corrective = work_orders_scope.where(maintenance_plan_id: nil).count
    @corrective_rate = @total_work_orders.positive? ? (@total_corrective.to_f / @total_work_orders * 100).round(1) : 0

    @total_parts_value = parts_value_for(work_orders_scope)

    completed = completed_with_dates(work_orders_scope)
    durations = downtime_hours(completed)
    @avg_downtime_hours = durations.any? ? (durations.sum / durations.size).round(1) : nil
    @total_downtime_hours = durations.sum.round(1)

    @per_vehicle = @vehicles.map do |v|
      v_incidents = company_incidents.where(vehicle_id: v.id)
      v_work_orders = WorkOrder.where(vehicle_id: v.id)
      v_completed = completed_with_dates(v_work_orders)
      v_durations = downtime_hours(v_completed)

      {
        vehicle: v,
        incidents: v_incidents.count,
        corrective: v_work_orders.where(maintenance_plan_id: nil).count,
        parts_value: parts_value_for(v_work_orders),
        avg_downtime: v_durations.any? ? (v_durations.sum / v_durations.size).round(1) : nil,
        total_downtime: v_durations.sum.round(1),
      }
    end

    @worst_vehicle_by_failures = @per_vehicle.max_by { |r| r[:incidents] + r[:corrective] }
    @worst_vehicle_by_downtime = @per_vehicle.max_by { |r| r[:total_downtime] }

    build_failures_chart(incidents_scope)
  end

  private

  def incidents_for_company
    current_user.superadmin? ? Incident.all : Incident.where(company_id: current_user.company_id)
  end

  def parts_value_for(work_orders_scope)
    usages = WorkOrderPartUsage.includes(:part).where(work_order_id: work_orders_scope.select(:id))
    usages.sum { |u| u.quantity * converted_cost(u.part) }
  end

  def completed_with_dates(work_orders_scope)
    work_orders_scope.where(status: :completed).where.not(start_date: nil).where.not(end_date: nil)
  end

  def downtime_hours(work_orders)
    work_orders.map { |wo| (wo.end_date - wo.start_date) / 1.hour }
  end

  def converted_cost(part)
    part.currency == "USD" ? part.cost * CurrencyConverter.usd_to_clp : part.cost
  end

  def build_failures_chart(incidents_scope)
    range_start = 5.months.ago.to_date.beginning_of_month
    recent = incidents_scope.where(created_at: range_start.beginning_of_day..)
    by_month = recent.group_by { |i| i.created_at.to_date.beginning_of_month }

    meses = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre]
    months = (0..5).map { |i| range_start.next_month(i) }
    @chart_labels = months.map { |m| "#{meses[m.month - 1]} #{m.year}" }
    @chart_incident_counts = months.map { |m| (by_month[m] || []).size }
  end
end
