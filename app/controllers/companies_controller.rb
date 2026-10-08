class CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_superadmin!
  before_action :set_company, only: [:edit, :update, :destroy]

  def index
    if params[:query].present?
      @companies = Company.where("name ILIKE :q OR rut ILIKE :q", q: "%#{params[:query]}%")
    else
      @companies = Company.all
    end
    @companies = @companies.order(:name)
  end

  def new
    @company = Company.new
    # Build initial admin user for the company
    @company.users.build(role: :admin)
  end

  def create
    @company = Company.new(company_create_params)
    # El admin inicial siempre se crea con rol admin, sin importar qué role
    # haya llegado en el parámetro (el campo del formulario es un hidden field
    # manipulable por el cliente).
    @company.users.each { |user| user.role = :admin }

    if @company.save
      redirect_to companies_path, notice: "Empresa creada exitosamente junto con su Administrador."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Capture the PREVIOUS state BEFORE modifying the object
    was_mechanic_enabled = @company.has_mechanic?
    was_analyst_enabled = @company.has_analyst?
    was_bodeguero_enabled = @company.has_bodeguero?

    @company.assign_attributes(company_update_params)

    # Detect if modules are being DISABLED
    mechanic_module_disabled = was_mechanic_enabled && !@company.has_mechanic?
    analyst_module_disabled = was_analyst_enabled && !@company.has_analyst?
    bodeguero_module_disabled = was_bodeguero_enabled && !@company.has_bodeguero?

    message = "Empresa actualizada correctamente."
    saved = ActiveRecord::Base.transaction do
      next false unless @company.save

      message += disable_role_module(:mecanico, "mecánicos") if mechanic_module_disabled
      message += disable_role_module(:analista, "analistas") if analyst_module_disabled
      message += disable_role_module(:bodeguero, "bodegueros") if bodeguero_module_disabled
      true
    end

    if saved
      redirect_to companies_path, notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @company.destroy
      redirect_to companies_path, notice: "Empresa y todos sus datos asociados fueron eliminados correctamente."
    else
      redirect_to companies_path, alert: "No se pudo eliminar la empresa."
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def disable_role_module(role, label)
    destroyed = @company.users.where(role: role).destroy_all
    destroyed.any? ? " Se eliminaron #{destroyed.size} #{label}." : ""
  end

  def ensure_superadmin!
    redirect_to root_path, alert: "Acceso denegado" unless current_user&.superadmin?
  end

  # Solo al crear una empresa se admite el usuario administrador anidado -
  # "Configurar" (update) no debe poder dar de alta usuarios como efecto
  # colateral de guardar los toggles de módulos.
  def company_create_params
    params.require(:company).permit(:name, :rut, :has_mechanic, :has_analyst, :has_bodeguero, :fuel_anomaly_threshold, users_attributes: [:email, :password, :password_confirmation, :role])
  end

  def company_update_params
    params.require(:company).permit(:name, :rut, :has_mechanic, :has_analyst, :has_bodeguero, :fuel_anomaly_threshold)
  end
end
