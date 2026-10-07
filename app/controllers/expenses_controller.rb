class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ]

  # GET /expenses or /expenses.json
  def index
    @expenses_scope = policy_scope(Expense).includes(:vehicle).order(date: :desc)
    @pagy, @expenses = pagy(@expenses_scope)
    authorize Expense
  end

  # GET /expenses/1 or /expenses/1.json
  def show
    authorize @expense
  end

  # GET /expenses/new
  def new
    @expense = Expense.new
    authorize @expense
  end

  # GET /expenses/1/edit
  def edit
    authorize @expense
  end

  # POST /expenses or /expenses.json
  def create
    @expense = Expense.new(expense_params)
    authorize @expense

    respond_to do |format|
      if @expense.save
        format.html { redirect_to @expense, notice: "Gasto creado exitosamente." }
        format.json { render :show, status: :created, location: @expense }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenses/1 or /expenses/1.json
  def update
    authorize @expense
    # Los archivos nuevos se suman a los ya guardados: asignarlos con update
    # reemplazaría (y borraría) las boletas que el gasto ya tenía.
    new_documents = Array(expense_params[:documents]).compact_blank
    @expense.assign_attributes(expense_params.except(:documents))
    @expense.documents.attach(new_documents) if new_documents.any?

    respond_to do |format|
      if @expense.save
        format.html { redirect_to @expense, notice: "Gasto actualizado exitosamente.", status: :see_other }
        format.json { render :show, status: :ok, location: @expense }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @expense.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1 or /expenses/1.json
  def destroy
    authorize @expense
    @expense.destroy!

    respond_to do |format|
      format.html { redirect_to expenses_path, notice: "Gasto eliminado exitosamente.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_expense
      @expense = Expense.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def expense_params
      params.require(:expense).permit(:vehicle_id, :category, :amount, :currency, :date, :provider, :description, :restricted_access, documents: [])
    end
end
