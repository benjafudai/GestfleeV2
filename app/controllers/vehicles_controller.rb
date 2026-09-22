class VehiclesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle, only: %i[show edit update destroy]

  def index
    authorize Vehicle
    @vehicles = Vehicle.all.order(:plate)
  end

  def show
    authorize @vehicle
    @documents = @vehicle.vehicle_documents.order(:due_on)
  end

  def new
    @vehicle = Vehicle.new
    authorize @vehicle
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    authorize @vehicle
    if @vehicle.save
      redirect_to @vehicle, notice: "Vehículo creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @vehicle
  end

  def update
    authorize @vehicle
    if @vehicle.update(vehicle_params)
      redirect_to @vehicle, notice: "Vehículo actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @vehicle
    @vehicle.destroy
    redirect_to vehicles_path, notice: "Vehículo eliminado."
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:plate, :brand, :model, :year, :status, :odometer)
  end
end