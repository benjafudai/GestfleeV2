class MaintenancePlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_maintenance_plan, only: %i[ show edit update destroy ]

  # GET /maintenance_plans or /maintenance_plans.json
  def index
    @pagy, @maintenance_plans = pagy(policy_scope(MaintenancePlan).order(:name))
    authorize MaintenancePlan
  end

  # GET /maintenance_plans/1 or /maintenance_plans/1.json
  def show
    authorize @maintenance_plan
  end

  # GET /maintenance_plans/new
  def new
    @maintenance_plan = MaintenancePlan.new
    authorize @maintenance_plan
  end

  # GET /maintenance_plans/1/edit
  def edit
    authorize @maintenance_plan
  end

  # POST /maintenance_plans or /maintenance_plans.json
  def create
    @maintenance_plan = MaintenancePlan.new(maintenance_plan_params)
    authorize @maintenance_plan

    respond_to do |format|
      if @maintenance_plan.save
        format.html { redirect_to @maintenance_plan, notice: "Plan de mantenimiento creado exitosamente." }
        format.json { render :show, status: :created, location: @maintenance_plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @maintenance_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /maintenance_plans/1 or /maintenance_plans/1.json
  def update
    authorize @maintenance_plan
    respond_to do |format|
      if @maintenance_plan.update(maintenance_plan_params)
        format.html { redirect_to @maintenance_plan, notice: "Plan de mantenimiento actualizado exitosamente.", status: :see_other }
        format.json { render :show, status: :ok, location: @maintenance_plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @maintenance_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /maintenance_plans/1 or /maintenance_plans/1.json
  def destroy
    authorize @maintenance_plan
    @maintenance_plan.destroy!

    respond_to do |format|
      format.html { redirect_to maintenance_plans_path, notice: "Plan de mantenimiento eliminado exitosamente.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_maintenance_plan
      @maintenance_plan = MaintenancePlan.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def maintenance_plan_params
      params.require(:maintenance_plan).permit(:name, :description, :interval_km, :interval_days, :interval_hours, maintenance_task_templates_attributes: [:id, :description, :expected_duration_minutes, :_destroy])
    end
end
