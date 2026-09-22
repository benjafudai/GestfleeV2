class VehicleDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle
  before_action :set_document, only: %i[edit update destroy]

  def new
    @document = @vehicle.vehicle_documents.build
    authorize @document
  end

  def create
    @document = @vehicle.vehicle_documents.build(document_params)
    authorize @document
    if @document.save
      redirect_to @vehicle, notice: "Documento creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @document
  end

  def update
    authorize @document
    if @document.update(document_params)
      redirect_to @vehicle, notice: "Documento actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @document
    @document.destroy
    redirect_to @vehicle, notice: "Documento eliminado."
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:vehicle_id])
  end

  def set_document
    @document = @vehicle.vehicle_documents.find(params[:id])
  end

  def document_params
    params.require(:vehicle_document).permit(:doc_type, :due_on, :notes, :status, :file)
  end
end
