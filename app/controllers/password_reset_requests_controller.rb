class PasswordResetRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    @pending_requests = scoped_requests.where(status: :pending).order(created_at: :desc)
  end

  def show
    @password_reset_request = scoped_requests.find(params[:id])
  end

  def update
    @password_reset_request = scoped_requests.find(params[:id])

    user = @password_reset_request.user
    
    if user.update(password: params[:password], password_confirmation: params[:password_confirmation], force_password_change: true)
      @password_reset_request.update!(status: :completed, admin: current_user)
      redirect_to password_reset_requests_path, notice: "La contraseña del usuario #{user.email} ha sido actualizada exitosamente."
    else
      redirect_to password_reset_request_path(@password_reset_request), alert: "Error al actualizar la contraseña: #{user.errors.full_messages.to_sentence}"
    end
  end

  private

  def authorize_admin!
    unless current_user.admin? || current_user.superadmin?
      redirect_to root_path, alert: "No tienes permisos para acceder a esta página."
    end
  end

  def scoped_requests
    base = PasswordResetRequest.joins(:user)
    current_user.superadmin? ? base : base.where(users: { company_id: current_user.company_id })
  end
end
