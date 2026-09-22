class ChecklistTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: %i[show edit update destroy]

  def index
    authorize ChecklistTemplate
    @templates = policy_scope(ChecklistTemplate).order(:name)
  end

  def show
    authorize @template
  end

  def new
    authorize ChecklistTemplate
    @template = ChecklistTemplate.new
    @template.checklist_items.build
  end

  def create
    authorize ChecklistTemplate
    @template = ChecklistTemplate.new(template_params)
    if @template.save
      redirect_to @template, notice: "Plantilla creada exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @template
  end

  def update
    authorize @template
    if @template.update(template_params)
      redirect_to @template, notice: "Plantilla actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @template
    @template.destroy
    redirect_to checklist_templates_path, notice: "Plantilla eliminada."
  end

  private

  def set_template
    @template = ChecklistTemplate.find(params[:id])
  end

  def template_params
    params.require(:checklist_template).permit(
      :name, :description,
      checklist_items_attributes: %i[id label item_type position required _destroy]
    )
  end
end
