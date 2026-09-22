class CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_superadmin!
  before_action :set_company, only: [:edit, :update]

  def index
    if params[:query].present?
      @companies = Company.where("name ILIKE ?", "%#{params[:query]}%")
    else
      @companies = Company.all
    end
    @companies = @companies.order(:name)
    @companies = @companies.order(:name)
  end

  def new
    @company = Company.new
    # Build initial admin user for the company
    @company.users.build(role: :admin)
  end

  def create
    @company = Company.new(company_params)
    
    # Force the role of the first user to be admin if it wasn't set (though we permit it conditionally)
    # The form will send role: 'admin' ideally, but let's enforce it for safety if needed or rely on param.
    
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
    
    Rails.logger.debug "=== UPDATE DEBUG ==="
    Rails.logger.debug "BEFORE: mechanic=#{was_mechanic_enabled}, analyst=#{was_analyst_enabled}"
    
    @company.assign_attributes(company_params)
    
    # Detect if modules are being DISABLED
    is_mechanic_enabled_now = @company.has_mechanic?
    is_analyst_enabled_now = @company.has_analyst?
    
    Rails.logger.debug "AFTER: mechanic=#{is_mechanic_enabled_now}, analyst=#{is_analyst_enabled_now}"
    
    mechanic_module_disabled = was_mechanic_enabled && !is_mechanic_enabled_now
    analyst_module_disabled = was_analyst_enabled && !is_analyst_enabled_now
    
    Rails.logger.debug "DISABLED: mechanic=#{mechanic_module_disabled}, analyst=#{analyst_module_disabled}"

    if @company.save
      message = "Empresa actualizada correctamente."
      deleted_count = 0
      
      if mechanic_module_disabled
        # Delete all mechanics from this company
        mechanics = @company.users.where(role: :mecanico)
        count = mechanics.count
        Rails.logger.debug "Found #{count} mechanics to delete"
        mechanics.destroy_all
        deleted_count += count
        message += " Se eliminaron #{count} mecánicos." if count > 0
      end
      
      if analyst_module_disabled
        # Delete all analysts from this company
        analysts = @company.users.where(role: :analista)
        count = analysts.count
        Rails.logger.debug "Found #{count} analysts to delete"
        analysts.destroy_all
        deleted_count += count
        message += " Se eliminaron #{count} analistas." if count > 0
      end

      redirect_to companies_path, notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    redirect_to companies_path, notice: "Empresa y todos sus datos asociados fueron eliminados correctamente."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def ensure_superadmin!
    redirect_to root_path, alert: "Acceso denegado" unless current_user&.superadmin?
  end

  def company_params
    params.require(:company).permit(:name, :rut, :has_mechanic, :has_analyst, :fuel_anomaly_threshold, :require_fuel_ticket, users_attributes: [:email, :password, :password_confirmation, :role])
  end
end
