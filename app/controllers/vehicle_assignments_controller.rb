class VehicleAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle
  before_action :set_assignment, only: [:destroy]

  def new
    @assignment = @vehicle.vehicle_assignments.build(started_on: Date.today)
    authorize @assignment
    @available_drivers = current_user.company.users.where(role: :chofer).order(:email)
  end

  def create
    @assignment = @vehicle.vehicle_assignments.build(assignment_params)
    authorize @assignment
    if @assignment.save
      redirect_to @vehicle, notice: "Chofer asignado correctamente."
    else
      @available_drivers = current_user.company.users.where(role: :chofer).order(:email)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @assignment
    @assignment.update!(ended_on: Date.today)
    redirect_to @vehicle, notice: "Asignación terminada correctamente."
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:vehicle_id])
  end

  def set_assignment
    @assignment = @vehicle.vehicle_assignments.find(params[:id])
  end

  def assignment_params
    params.require(:vehicle_assignment).permit(:user_id, :started_on, :notes)
  end
end
