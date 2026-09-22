class IncidentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_incident, only: %i[ show edit update ]

  def index
    @incidents = policy_scope(Incident).includes(:vehicle, :reporter).order(created_at: :desc)
  end

  def show
    authorize @incident
  end

  def new
    @incident = Incident.new
    authorize @incident
  end

  def create
    @incident = Incident.new(incident_params)
    @incident.reporter = current_user
    authorize @incident

    if @incident.save
      redirect_to @incident, notice: "Incidente reportado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @incident
  end

  def update
    authorize @incident
    if @incident.update(incident_update_params)
      redirect_to @incident, notice: "Incidente actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  # Al crear, el chofer NO puede fijar el estado (siempre nace "pending").
  def incident_params
    params.require(:incident).permit(:vehicle_id, :description, :severity, :latitude, :longitude, photos: [])
  end

  # Al editar, sí se permite cambiar el estado (lo hace admin/mecánico/superadmin, ver update?).
  def incident_update_params
    params.require(:incident).permit(:vehicle_id, :description, :severity, :status, :latitude, :longitude, photos: [])
  end
end
