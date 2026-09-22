class IncidentsController < ApplicationController
  before_action :set_incident, only: %i[ show edit update ]

  def index
    @incidents = policy_scope(Incident).order(created_at: :desc)
  end

  def show
    authorize @incident
  end

  def new
    @incident = Incident.new
    authorize @incident
  end

  def create
    @incident = Current.company.incidents.build(incident_params)
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
    if @incident.update(incident_params)
      redirect_to @incident, notice: "Incidente actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(:vehicle_id, :description, :severity, :status, :latitude, :longitude, photos: [])
  end
end
