class WorkOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_order, only: %i[ show edit update destroy change_status ]

  # GET /work_orders or /work_orders.json
  def index
    @work_orders = policy_scope(WorkOrder).includes(:vehicle, :maintenance_plan, :mechanic)
    authorize WorkOrder
  end

  # GET /work_orders/1 or /work_orders/1.json
  def show
    authorize @work_order
  end

  # GET /work_orders/new
  def new
    @work_order = WorkOrder.new
    authorize @work_order
  end

  # GET /work_orders/1/edit
  def edit
    authorize @work_order
  end

  # POST /work_orders or /work_orders.json
  def create
    @work_order = WorkOrder.new(work_order_params)
    authorize @work_order

    respond_to do |format|
      if @work_order.save
        format.html { redirect_to @work_order, notice: "Orden de trabajo creada exitosamente." }
        format.json { render :show, status: :created, location: @work_order }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @work_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /work_orders/1 or /work_orders/1.json
  def update
    authorize @work_order
    respond_to do |format|
      if @work_order.update(work_order_params)
        format.html { redirect_to @work_order, notice: "Orden de trabajo actualizada exitosamente.", status: :see_other }
        format.json { render :show, status: :ok, location: @work_order }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @work_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /work_orders/1 or /work_orders/1.json
  def destroy
    authorize @work_order
    @work_order.destroy!

    respond_to do |format|
      format.html { redirect_to work_orders_path, notice: "Orden de trabajo eliminada exitosamente.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # PATCH /work_orders/1/change_status
  def change_status
    authorize @work_order
    new_status = params[:status]
    if WorkOrder.statuses.keys.include?(new_status)
      if @work_order.update(status: new_status)
        redirect_to @work_order, notice: "Estado actualizado exitosamente."
      else
        redirect_to @work_order, alert: @work_order.errors.full_messages.to_sentence.presence || "No se pudo actualizar el estado."
      end
    else
      redirect_to @work_order, alert: "Estado inválido."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_work_order
      @work_order = WorkOrder.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def work_order_params
      params.require(:work_order).permit(:vehicle_id, :maintenance_plan_id, :status, :start_date, :end_date, :mechanic_id, :notes, work_order_tasks_attributes: [:id, :description, :completed, :_destroy], work_order_part_usages_attributes: [:id, :part_id, :quantity, :_destroy])
    end
end
