class PartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_part, only: %i[show edit update destroy]

  def index
    authorize Part
    @pagy, @parts = pagy(policy_scope(Part).order(:name))
  end

  def show
    authorize @part
  end

  def new
    authorize Part
    @part = Part.new
  end

  def edit
    authorize @part
  end

  def create
    authorize Part
    @part = Part.new(part_params)

    if @part.save
      redirect_to @part, notice: 'Repuesto creado correctamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @part
    if @part.update(part_params)
      redirect_to @part, notice: 'Repuesto actualizado correctamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @part
    @part.destroy
    redirect_to parts_url, notice: 'Repuesto eliminado exitosamente.'
  end

  private

  def set_part
    @part = Part.find(params[:id])
  end

  def part_params
    params.require(:part).permit(:sku, :name, :unit_of_measure, :stock, :cost, :currency, vehicle_ids: [])
  end
end
