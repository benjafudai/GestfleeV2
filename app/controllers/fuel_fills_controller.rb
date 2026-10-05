class FuelFillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle, only: %i[new create index]
  before_action :set_fuel_fill, only: %i[show edit update destroy]

  def index
    if @vehicle
      @fuel_fills = policy_scope(FuelFill).where(vehicle: @vehicle)
                                           .includes(:vehicle, :user)
                                           .order(date: :desc, odometer: :desc)
    else
      @fuel_fills = policy_scope(FuelFill).includes(:vehicle, :user)
                                           .order(date: :desc, odometer: :desc)
    end
    authorize @fuel_fills
    build_vehicle_options
    build_fuel_stats
  end

  def show
    authorize @fuel_fill
  end

  def new
    @fuel_fill = @vehicle.fuel_fills.new(date: Date.today, odometer: @vehicle.odometer)
    authorize @fuel_fill
  end

  def edit
    authorize @fuel_fill
  end

  def create
    @fuel_fill = @vehicle.fuel_fills.new(fuel_fill_params)
    @fuel_fill.user = current_user

    authorize @fuel_fill

    if @fuel_fill.save
      redirect_to vehicle_fuel_fills_path(@vehicle), notice: "Carga de combustible registrada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @fuel_fill
    if @fuel_fill.update(fuel_fill_params)
      redirect_to fuel_fill_path(@fuel_fill), notice: "Registro de combustible actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @fuel_fill
    vehicle = @fuel_fill.vehicle
    @fuel_fill.destroy
    redirect_to vehicle_fuel_fills_path(vehicle), notice: "Registro eliminado."
  end

  private

  def set_vehicle
    if params[:vehicle_id]
      @vehicle = Vehicle.find(params[:vehicle_id])
    end
  end

  def set_fuel_fill
    @fuel_fill = FuelFill.find(params[:id])
  end

  def fuel_fill_params
    params.require(:fuel_fill).permit(:liters, :cost, :currency, :odometer, :date, :notes, :ticket)
  end

  def build_vehicle_options
    return if current_user.chofer?

    @vehicles = if current_user.superadmin?
      Vehicle.unscoped.order(:plate)
    else
      (current_user.company&.vehicles || Vehicle.none).order(:plate)
    end
  end

  def build_fuel_stats
    @total_liters = @fuel_fills.sum(:liters)
    @total_cost = @fuel_fills.sum(:cost)
    @avg_price_per_liter = @total_liters.to_f.positive? ? @total_cost / @total_liters : 0
    @avg_km_per_liter = @fuel_fills.where.not(km_per_liter: nil).average(:km_per_liter)&.round(2)

    unless @vehicle
      @top_vehicle = @fuel_fills.reorder(nil)
                                 .joins(:vehicle)
                                 .group("vehicles.plate")
                                 .sum(:cost)
                                 .max_by { |_plate, cost| cost }
    end

    range_start = 5.months.ago.to_date.beginning_of_month
    recent_fills = @fuel_fills.select { |f| f.date >= range_start }
    by_month = recent_fills.group_by { |f| f.date.beginning_of_month }

    meses = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre]
    months = (0..5).map { |i| range_start.next_month(i) }
    @chart_labels = months.map { |m| "#{meses[m.month - 1]} #{m.year}" }
    @chart_liters = months.map { |m| (by_month[m] || []).sum(&:liters) }
    @chart_costs  = months.map { |m| (by_month[m] || []).sum(&:cost) }
  end
end
