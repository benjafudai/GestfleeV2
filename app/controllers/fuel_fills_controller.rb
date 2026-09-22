class FuelFillsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle, only: %i[new create index]
  before_action :set_fuel_fill, only: %i[show edit update destroy]

  def index
    @company_vehicles = Current.company&.vehicles&.order(:plate) || Vehicle.none

    if @vehicle
      @fuel_fills = policy_scope(FuelFill).where(vehicle: @vehicle)
                                           .includes(:vehicle, :user)
                                           .order(date: :desc, odometer: :desc)
    else
      @fuel_fills = policy_scope(FuelFill).includes(:vehicle, :user)
                                           .order(date: :desc, odometer: :desc)
    end
    authorize @fuel_fills
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
end
