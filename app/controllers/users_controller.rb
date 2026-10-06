class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_superadmin!
  before_action :ensure_superadmin!, only: :unlock

  def index
    @users = scoped_users.includes(:company).order(:role, :email)

    # Filter by Company Name (only for SuperAdmin)
    if current_user.superadmin? && params[:company_name].present?
      @users = @users.joins(:company).where("companies.name ILIKE ?", "%#{params[:company_name]}%")
    end

    # Filter by Role
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end

    @pagy, @users = pagy(@users)
  end

  def show
    @user = find_scoped_user
  end

  def new
    @user = User.new
    @available_roles = available_roles_for_current_user
  end

  def create
    @user = User.new(user_params)
    
    # Auto-assign company for Admins
    if current_user.admin?
      @user.company = current_user.company
    elsif current_user.superadmin?
      # For superadmin role, explicitly clear company (no company required)
      if @user.role == 'superadmin'
        @user.company_id = nil
      elsif params[:user][:company_id].present?
        @user.company_id = params[:user][:company_id]
      end
    end
    
    # Validate role restrictions
    unless role_allowed_for_current_user?(@user.role)
      @user.errors.add(:role, "no está permitido para tu nivel de acceso")
      @available_roles = available_roles_for_current_user
      render :new, status: :unprocessable_entity
      return
    end
    
    if @user.save
      redirect_to users_path, notice: "Usuario creado correctamente."
    else
      @available_roles = available_roles_for_current_user
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = find_scoped_user
    @available_roles = available_roles_for_current_user
  end

  def update
    @user = find_scoped_user

    unless role_allowed_for_current_user?(edit_user_params[:role] || @user.role)
      @user.errors.add(:role, "no está permitido para tu nivel de acceso")
      @available_roles = available_roles_for_current_user
      render :edit, status: :unprocessable_entity
      return
    end

    was_last_admin = last_admin_of_company?(@user)

    @user.assign_attributes(edit_user_params)
    # Un superadmin es global: si se cambia el rol a superadmin, no debe
    # quedar atado a la empresa que tenía antes (mismo resguardo que create).
    @user.company_id = nil if @user.role == "superadmin"

    if was_last_admin && @user.role != "admin"
      @user.errors.add(:role, "no se puede cambiar: es el único administrador de su empresa")
      @available_roles = available_roles_for_current_user
      render :edit, status: :unprocessable_entity
      return
    end

    if @user.save
      redirect_to @user, notice: "Usuario actualizado correctamente."
    else
      @available_roles = available_roles_for_current_user
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user = find_scoped_user
    if @user == current_user
      redirect_to users_path, alert: "No puedes eliminarte a ti mismo."
    elsif last_admin_of_company?(@user)
      redirect_to users_path, alert: "No puedes eliminar al único administrador de #{@user.company.name}. Crea otro admin antes de eliminar este."
    else
      @user.destroy
      redirect_to users_path, notice: "Usuario eliminado."
    end
  end

  # Accounts lock after too many failed logins and unlock on their own after
  # Devise's unlock_in; the GestFlee team (superadmins) can unlock one right away.
  def unlock
    @user = User.find(params[:id])

    if @user.access_locked?
      @user.unlock_access!
      redirect_back fallback_location: user_path(@user), notice: "La cuenta de #{@user.email} fue desbloqueada."
    else
      redirect_back fallback_location: user_path(@user), notice: "La cuenta de #{@user.email} no estaba bloqueada."
    end
  end

  private

  def scoped_users
    current_user.superadmin? ? User.all : current_user.company.users
  end

  def find_scoped_user
    scoped_users.find(params[:id])
  end

  def last_admin_of_company?(user)
    user.admin? && user.company.present? && user.company.users.where(role: :admin).count <= 1
  end

  def ensure_admin_or_superadmin!
    unless current_user&.superadmin? || current_user&.admin?
      redirect_to root_path, alert: "Acceso denegado"
    end
  end

  def ensure_superadmin!
    redirect_to root_path, alert: "Acceso denegado" unless current_user.superadmin?
  end
  
  def available_roles_for_current_user
    if current_user.superadmin?
      # SuperAdmin can assign any role
      User.roles.keys
    else
      # Admin can only assign: chofer, mecanico, analista, bodeguero
      ['chofer', 'mecanico', 'analista', 'bodeguero']
    end
  end
  
  def role_allowed_for_current_user?(role)
    available_roles_for_current_user.include?(role.to_s)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :company_id)
  end

  def edit_user_params
    if current_user.superadmin?
      params.require(:user).permit(:email, :role, :company_id)
    else
      params.require(:user).permit(:email, :role)
    end
  end
end
