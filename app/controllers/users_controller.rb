class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin_or_superadmin!

  def index
    # Scope users based on role
    if current_user.superadmin?
      # SuperAdmin sees all users
      @users = User.includes(:company).order(:role, :email)
    else
      # Admin sees only users from their company
      @users = current_user.company.users.includes(:company).order(:role, :email)
    end

    # Filter by Company Name (only for SuperAdmin)
    if current_user.superadmin? && params[:company_name].present?
      @users = @users.joins(:company).where("companies.name ILIKE ?", "%#{params[:company_name]}%")
    end

    # Filter by Role
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end
  end

  def show
    if current_user.superadmin?
      @user = User.find(params[:id])
    else
      @user = current_user.company.users.find(params[:id])
    end
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

  def destroy
    @user = User.find(params[:id])
    if @user == current_user
      redirect_to users_path, alert: "No puedes eliminarte a ti mismo."
    else
      @user.destroy
      redirect_to users_path, notice: "Usuario eliminado."
    end
  end

  private

  def ensure_admin_or_superadmin!
    unless current_user&.superadmin? || current_user&.admin?
      redirect_to root_path, alert: "Acceso denegado"
    end
  end
  
  def available_roles_for_current_user
    if current_user.superadmin?
      # SuperAdmin can assign any role
      User.roles.keys
    else
      # Admin can only assign: chofer, mecanico, analista
      ['chofer', 'mecanico', 'analista']
    end
  end
  
  def role_allowed_for_current_user?(role)
    available_roles_for_current_user.include?(role.to_s)
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :company_id)
  end
end
