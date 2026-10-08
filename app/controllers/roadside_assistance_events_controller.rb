class RoadsideAssistanceEventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    @events = policy_scope(RoadsideAssistanceEvent).order(created_at: :desc)
    authorize @events
    @pagy, @events = pagy(@events)
  end

  def show
  end

  def new
    @event = RoadsideAssistanceEvent.new
    authorize @event
    # Provide the currently assigned vehicle if the user is a chofer
    if current_user.chofer? && current_user.active_assignment
      @event.vehicle = current_user.active_assignment.vehicle
    end
  end

  def edit
  end

  def create
    @event = RoadsideAssistanceEvent.new(event_params)
    @event.user = current_user
    @event.company = Current.company
    authorize @event

    if @event.save
      redirect_to @event, notice: "El auxilio en ruta fue reportado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "El estado del auxilio fue actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to roadside_assistance_events_url, notice: "El evento fue eliminado."
  end

  private

  def set_event
    @event = RoadsideAssistanceEvent.find(params[:id])
    authorize @event
  end

  def event_params
    params.require(:roadside_assistance_event).permit(:vehicle_id, :status, :latitude, :longitude, :description, photos: [])
  end
end
