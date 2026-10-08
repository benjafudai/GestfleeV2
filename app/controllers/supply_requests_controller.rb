class SupplyRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supply_request, only: %i[show edit update destroy change_status]

  def index
    authorize SupplyRequest
    @pagy, @supply_requests = pagy(policy_scope(SupplyRequest).includes(:vehicle, :user, :supply_request_lines).order(created_at: :desc))
  end

  def show
    authorize @supply_request
  end

  def new
    authorize SupplyRequest
    @supply_request = SupplyRequest.new
    @supply_request.supply_request_lines.build
    
    @vehicles = Vehicle.active.order(:plate)
  end

  def create
    authorize SupplyRequest
    @supply_request = SupplyRequest.new(supply_request_params)
    @supply_request.user = current_user
    @supply_request.status = :requested

    if @supply_request.save
      redirect_to @supply_request, notice: 'Solicitud de suministros creada exitosamente.'
    else
      @vehicles = Vehicle.active.order(:plate)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @supply_request
    @vehicles = Vehicle.active.order(:plate)
  end

  def update
    authorize @supply_request
    if @supply_request.update(supply_request_params)
      redirect_to @supply_request, notice: 'Solicitud actualizada correctamente.'
    else
      @vehicles = Vehicle.active.order(:plate)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @supply_request
    @supply_request.destroy
    redirect_to supply_requests_url, notice: 'Solicitud eliminada.'
  end

  def change_status
    authorize @supply_request
    
    new_status = params[:status]
    if SupplyRequest.statuses.keys.include?(new_status)
      if @supply_request.update(status: new_status)
        redirect_to @supply_request, notice: "Estado de la solicitud actualizado."
      else
        redirect_to @supply_request, alert: @supply_request.errors.full_messages.to_sentence.presence || 'No se pudo actualizar el estado.'
      end
    else
      redirect_to @supply_request, alert: 'Estado no válido.'
    end
  end

  private

  def set_supply_request
    @supply_request = SupplyRequest.find(params[:id])
  end

  def supply_request_params
    params.require(:supply_request).permit(
      :vehicle_id, 
      :admin_notes,
      supply_request_lines_attributes: [:id, :part_id, :quantity, :_destroy]
    )
  end
end
