class VehicleAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle
  before_action :set_assignment, only: [:destroy]

  def new
    @assignment = @vehicle.vehicle_assignments.build(started_on: Date.today)
    authorize @assignment
    @available_drivers = available_drivers
  end

  def create
    @assignment = @vehicle.vehicle_assignments.build(assignment_params)
    authorize @assignment
    if @assignment.save
      redirect_to @vehicle, notice: "Chofer asignado correctamente."
    else
      @available_drivers = available_drivers
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @assignment
    if @assignment.update(ended_on: Date.today)
      redirect_to @vehicle, notice: "Asignación terminada correctamente."
    else
      redirect_to @vehicle, alert: @assignment.errors.full_messages.to_sentence.presence || "No se pudo terminar la asignación."
    end
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:vehicle_id])
  end

  def set_assignment
    @assignment = @vehicle.vehicle_assignments.find(params[:id])
  end

  def available_drivers
    @vehicle.company.users.where(role: :chofer).order(:email)
  end

  def assignment_params
    params.require(:vehicle_assignment).permit(:user_id, :started_on, :notes)
  end
end
